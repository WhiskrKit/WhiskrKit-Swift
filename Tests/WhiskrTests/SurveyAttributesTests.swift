//
//  SurveyAttributesTests.swift
//  WhiskrKitTests
//

import Testing
import Foundation
@testable import WhiskrKit

@MainActor
private final class RecordingConfigurationService: ConfigurationService {
    let networkService: NetworkService
    var submitted: [(surveyId: String, response: SurveyResponse)] = []
    var shouldSucceed = true
    var queue: SubmissionQueue?

    init(networkService: NetworkService = MockNetworkService()) {
        self.networkService = networkService
    }

    func fetchSurveyTemplate<T>(for identifier: String) async throws -> T? where T: Decodable { nil }
    func submitSurveyResponse(surveyId: String, response: SurveyResponse) async -> Bool {
        submitted.append((surveyId, response))
        if !shouldSucceed { queue?.enqueue(PendingSubmission(surveyId: surveyId, response: response)) }
        return shouldSucceed
    }
    func recordImpression(surveyId: String, event: SurveyImpressionEvent, trigger: SurveyImpressionTrigger) async {}
    func retryPendingSubmissions() async {}
    func configure(apiKey: String) {}
}

private func json(_ response: SurveyResponse) throws -> [String: Any] {
    let data = try JSONEncoder().encode(response)
    return try JSONSerialization.jsonObject(with: data) as! [String: Any]
}

private func rawJSON(_ value: AttributeValue) throws -> String {
    let data = try JSONEncoder().encode(["v": value])
    return String(decoding: data, as: UTF8.self)
}

@Suite("Attribute wire format")
struct AttributeWireFormatTests {
    @Test("String, number and bool encode as plain JSON values")
    func shape() throws {
        let response = SurveyResponse(
            results: ["q": .symbolRating(5)],
            attributes: ["plan": "pro", "sessions": 3, "beta": true, "ratio": 0.5]
        )
        let attrs = try #require(try json(response)["attributes"] as? [String: Any])
        #expect(attrs["plan"] as? String == "pro")
        #expect(attrs["sessions"] as? Int == 3)
        #expect(attrs["beta"] as? Bool == true)
        #expect(attrs["ratio"] as? Double == 0.5)
    }

    @Test("Integral numbers serialize as 3, not 3.0")
    func integralNumber() throws {
        #expect(try rawJSON(.number(3)) == #"{"v":3}"#)
        #expect(try rawJSON(.number(-7)) == #"{"v":-7}"#)
        #expect(try rawJSON(.number(2.5)) == #"{"v":2.5}"#)
    }

    @Test("NaN and infinity are rejected")
    func nonFinite() {
        #expect(throws: (any Error).self) { try JSONEncoder().encode(AttributeValue.number(.nan)) }
        #expect(throws: (any Error).self) { try JSONEncoder().encode(AttributeValue.number(.infinity)) }
    }

    @Test("Attributes are omitted when nil or empty")
    func omitted() throws {
        #expect(try json(SurveyResponse(results: [:]))["attributes"] == nil)
        #expect(try json(SurveyResponse(results: [:], attributes: [:]))["attributes"] == nil)
    }

    @Test("Values round trip with their type")
    func roundTrip() throws {
        let original = SurveyResponse(results: ["q": .npsRating(8)], attributes: ["a": "x", "b": 4, "c": false])
        let decoded = try JSONDecoder().decode(SurveyResponse.self, from: JSONEncoder().encode(original))
        #expect(decoded.attributes?["a"] == .string("x"))
        #expect(decoded.attributes?["b"] == .number(4))
        #expect(decoded.attributes?["c"] == .bool(false))
    }

    @Test("Old SurveyResponse JSON without attributes still decodes")
    func oldResponse() throws {
        let old = #"{"results":{"q":{"symbolRating":5}}}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SurveyResponse.self, from: old)
        #expect(decoded.attributes == nil)
        #expect(decoded.results["q"] == .symbolRating(5))
    }

    @Test("Old persisted PendingSubmission JSON still decodes")
    func oldPending() throws {
        let pending = PendingSubmission(surveyId: "s", response: SurveyResponse(results: ["q": .symbolRating(5)]))
        let data = try JSONEncoder().encode(pending)
        // The encoded form has no attributes key, exactly like data written by an older SDK.
        #expect(!String(decoding: data, as: UTF8.self).contains("attributes"))
        let decoded = try JSONDecoder().decode(PendingSubmission.self, from: data)
        #expect(decoded.response.attributes == nil)
    }
}

@Suite("Attribute sanitizer")
struct AttributeSanitizerTests {
    @Test("Keeps at most 20 keys, dropping the rest in sorted order")
    func maxKeys() {
        var input: [String: AttributeValue] = [:]
        for i in 0..<21 { input[String(format: "k%02d", i)] = .number(Double(i)) }
        let out = SurveyAttributesSanitizer.sanitize(input)
        #expect(out.count == 20)
        #expect(out["k19"] != nil)
        #expect(out["k20"] == nil)
    }

    @Test("Keys are trimmed, empty and over 64 character keys dropped")
    func keyLimits() {
        let out = SurveyAttributesSanitizer.sanitize([
            "  plan ": "pro",
            "   ": "x",
            "": "x",
            String(repeating: "a", count: 64): "ok",
            String(repeating: "a", count: 65): "too long"
        ])
        #expect(out["plan"] == "pro")
        #expect(out.count == 2)
        #expect(out[String(repeating: "a", count: 64)] != nil)
    }

    @Test("Strings are truncated to 256 characters")
    func stringLimit() {
        let out = SurveyAttributesSanitizer.sanitize(["s": .string(String(repeating: "é", count: 300))])
        guard case .string(let value) = out["s"] else { Issue.record("missing"); return }
        #expect(value.count == 256)
    }

    @Test("Non finite numbers are dropped")
    func nonFinite() {
        let out = SurveyAttributesSanitizer.sanitize(["a": .number(.nan), "b": .number(1)])
        #expect(out.keys.sorted() == ["b"])
    }

    @Test("Everything is dropped when over 2 KB")
    func totalSize() {
        var input: [String: AttributeValue] = [:]
        for i in 0..<12 { input[String(format: "key%02d", i)] = .string(String(repeating: "x", count: 256)) }
        #expect(SurveyAttributesSanitizer.sanitize(input).isEmpty)

        let small = SurveyAttributesSanitizer.sanitize(["a": "b"])
        #expect(SurveyAttributesSanitizer.encodedSize(small) <= 2048)
    }

    @Test("Personal data key detection normalizes case and punctuation")
    func personalKeys() {
        for key in ["email", "E-Mail", "user_phone", "MobileNumber", "iban", "bsn", "Passport No", "home address",
                    "credit_card", "name", "First Name", "last-name", "ZIP", "postal_code", "Postcode"] {
            #expect(PersonalDataHeuristics.isPersonalDataKey(key), "\(key)")
        }
        for key in ["plan", "sessions", "beta", "username_count", "company", "filename"] {
            #expect(!PersonalDataHeuristics.isPersonalDataKey(key), "\(key)")
        }
    }

    @Test("Value heuristics spot emails and IBANs")
    func valueHeuristics() {
        #expect(PersonalDataHeuristics.looksLikeEmail("a@b.nl"))
        #expect(!PersonalDataHeuristics.looksLikeEmail("pro"))
        #expect(PersonalDataHeuristics.looksLikeIBAN("NL91 ABNA 0417 1643 00"))
        #expect(!PersonalDataHeuristics.looksLikeIBAN("premium"))
    }

    @Test("Detection warns only: nothing is stripped")
    func neverStrips() {
        let out = SurveyAttributesSanitizer.sanitize(["email": "a@b.nl"])
        #expect(out["email"] == "a@b.nl")
    }
}

@MainActor
@Suite("Attribute API and submit")
struct AttributeSubmitTests {
    private func make(success: Bool = true) -> (WhiskrKit, RecordingConfigurationService) {
        let service = RecordingConfigurationService()
        service.shouldSucceed = success
        return (WhiskrKit(configurationService: service, apiKey: "k"), service)
    }

    @Test("set, merge, remove and clear")
    func api() {
        let (kit, _) = make()
        kit.setAttribute("plan", "pro")
        kit.setAttributes(["sessions": 3, "plan": "free"])
        #expect(kit.surveyAttributes == ["plan": "free", "sessions": 3])
        kit.setAttribute("sessions", nil)
        #expect(kit.surveyAttributes == ["plan": "free"])
        kit.removeAttribute("plan")
        #expect(kit.surveyAttributes.isEmpty)
        kit.setAttributes(["a": true, "b": 1])
        kit.clearAttributes()
        #expect(kit.surveyAttributes.isEmpty)
    }

    @Test("Keys are trimmed on set and remove, so ' plan' and 'plan' are one attribute")
    func trimmedKeys() {
        let (kit, _) = make()
        kit.setAttribute("plan", "free")
        kit.setAttribute(" plan ", "pro")
        #expect(kit.surveyAttributes == ["plan": "pro"])
        kit.removeAttribute("plan ")
        #expect(kit.surveyAttributes.isEmpty)
    }

    @Test("Submit attaches attributes snapshotted at submit time")
    func snapshotAtSubmit() async throws {
        let (kit, service) = make()
        kit.setAttribute("plan", "free")
        // Survey presented here; value changes before the user submits.
        kit.setAttribute("plan", "pro")
        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: ["q": .symbolRating(4)]))
        #expect(service.submitted.first?.response.attributes == ["plan": "pro"])

        // Later changes do not touch the already submitted copy.
        kit.setAttribute("plan", "enterprise")
        #expect(service.submitted.first?.response.attributes == ["plan": "pro"])
    }

    @Test("Submit without attributes sends none")
    func none() async {
        let (kit, service) = make()
        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: [:]))
        #expect(service.submitted.first?.response.attributes == nil)
    }

    @Test("Submit sanitizes attributes")
    func sanitizedOnSubmit() async {
        let (kit, service) = make()
        kit.setAttribute("long", .string(String(repeating: "a", count: 300)))
        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: [:]))
        guard case .string(let value)? = service.submitted.first?.response.attributes?["long"] else {
            Issue.record("missing"); return
        }
        #expect(value.count == 256)
    }

    @Test("A failed submission keeps its attributes through the storage round trip")
    func queuedRetainsAttributes() async throws {
        let suite = "test.whiskrkit.attributes"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let storage = UserDefaultsSubmissionStorage(userDefaults: defaults, key: "pending")
        let queue = SubmissionQueue(storage: storage)

        let (kit, service) = make(success: false)
        service.queue = queue
        kit.setAttributes(["plan": "pro", "sessions": 3, "beta": true])
        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: ["q": .npsRating(9)]))

        let reloaded = UserDefaultsSubmissionStorage(userDefaults: defaults, key: "pending").load()
        #expect(reloaded.count == 1)
        #expect(reloaded.first?.response.attributes == ["plan": "pro", "sessions": 3, "beta": true])
    }

    @Test("Mock mode still accepts submissions with attributes")
    func mockMode() async {
        let kit = WhiskrKit(configurationService: MockConfigurationService(), apiKey: "k")
        kit.setAttribute("plan", "pro")
        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: [:]))
        #expect(kit.surveyAttributes["plan"] == "pro")
    }
}
