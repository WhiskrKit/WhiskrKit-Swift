//
//  StoreReviewFollowUpTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import Testing
@testable import WhiskrKit

@MainActor
private final class FakeStoreReviewRequester: StoreReviewRequester {
    var requestCount = 0
    func requestReview() -> Bool {
        requestCount += 1
        return true
    }
}

@MainActor
private final class InMemoryStoreReviewStorage: StoreReviewStorage {
    var lastRequestedAppVersion: String?
}

@MainActor
private final class StubConfigurationService: ConfigurationService {
    let networkService: NetworkService = MockNetworkService()
    var shouldSucceed = true

    func fetchSurveyTemplate<T>(for identifier: String) async throws -> T? where T: Decodable { nil }
    func submitSurveyResponse(surveyId: String, response: SurveyResponse) async -> Bool { shouldSucceed }
    func recordImpression(surveyId: String, event: SurveyImpressionEvent, trigger: SurveyImpressionTrigger) async {}
    func retryPendingSubmissions() async {}
    func configure(apiKey: String) {}
}

private func star(_ id: String, opensStoreReview: Bool) -> SurveyPresentation {
    SurveyPresentation(surveyBase: .symbolRating(base: SymbolRatingTemplate(
        id: id, title: nil, description: nil, opensStoreReview: opensStoreReview,
        isRequired: false, A11yLabel: nil, A11yHint: nil
    )))
}

private func sheet(opensStoreReview: Bool) -> SheetTemplate {
    SheetTemplate(id: "s1", title: nil, description: nil, followUpQuestion: nil,
                  survey: star("q1", opensStoreReview: opensStoreReview))
}

@MainActor
@Suite("App Store review follow-up")
struct StoreReviewFollowUpTests {
    private let requester = FakeStoreReviewRequester()
    private let storage = InMemoryStoreReviewStorage()
    private let service = StubConfigurationService()

    private func makeKit(mocked: Bool = false, version: @escaping () -> String? = { "1.0" }) -> WhiskrKit {
        // One shared, emptied suite: completion tracking writes there, the assertions never read it.
        let suite = "StoreReviewFollowUpTests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return WhiskrKit(
            configurationService: service,
            apiKey: "test",
            usesMockedSurveys: mocked,
            eligibilityStorage: UserDefaultsEligibilityStorage(userDefaults: defaults),
            storeReviewFollowUp: StoreReviewFollowUp(
                requester: requester, storage: storage, appVersion: version, delay: .zero
            )
        )
    }

    private func submit(_ kit: WhiskrKit, rating: Int, template: SheetTemplate = sheet(opensStoreReview: true)) async {
        await kit.submitSurveyResponse(
            surveyId: template.id,
            response: SurveyResponse(results: ["q1": .symbolRating(rating)]),
            storeReviewQuestionIds: template.storeReviewQuestionIds
        )
    }

    @Test("Fires at 4 and 5 stars", arguments: [4, 5])
    func firesOnHighRating(_ rating: Int) async {
        await submit(makeKit(), rating: rating)
        #expect(requester.requestCount == 1)
        #expect(storage.lastRequestedAppVersion == "1.0")
    }

    @Test("Does not fire at 1 to 3 stars", arguments: [1, 2, 3])
    func silentOnLowRating(_ rating: Int) async {
        await submit(makeKit(), rating: rating)
        #expect(requester.requestCount == 0)
        #expect(storage.lastRequestedAppVersion == nil)
    }

    @Test("Does not fire when the question has opensStoreReview off")
    func silentWhenFlagOff() async {
        await submit(makeKit(), rating: 5, template: sheet(opensStoreReview: false))
        #expect(requester.requestCount == 0)
    }

    @Test("Does not fire when the submission fails")
    func silentWhenSubmissionFails() async {
        service.shouldSucceed = false
        await submit(makeKit(), rating: 5)
        #expect(requester.requestCount == 0)
        #expect(storage.lastRequestedAppVersion == nil)
    }

    @Test("Fires once per app version, and again after a version change")
    func oncePerVersion() async {
        var version = "1.0"
        let kit = makeKit(version: { version })
        await submit(kit, rating: 5)
        await submit(kit, rating: 5)
        #expect(requester.requestCount == 1)

        version = "1.1"
        await submit(kit, rating: 4)
        #expect(requester.requestCount == 2)
        #expect(storage.lastRequestedAppVersion == "1.1")
    }

    @Test("Mock mode never calls StoreKit or stores a version")
    func mockModeOnlyLogs() async {
        let kit = makeKit(mocked: true)
        await submit(kit, rating: 5)
        await submit(kit, rating: 5)
        #expect(requester.requestCount == 0)
        #expect(storage.lastRequestedAppVersion == nil)
    }

    @Test("A full-screen form with a qualifying star question among others fires")
    func fullScreenForm() async {
        let form = FullScreenFormTemplate(
            id: "f1", title: nil, subtitle: nil, description: nil,
            surveys: [
                SurveyPresentation(surveyBase: .scaleRating(base: ScaleRatingTemplate(
                    id: "nps", title: nil, subtitle: nil, ratingRange: .init(min: 0, max: 10),
                    isRequired: false, A11yLabel: nil, A11yHint: nil
                ))),
                star("plain-star", opensStoreReview: false),
                star("review-star", opensStoreReview: true),
            ]
        )
        #expect(form.storeReviewQuestionIds == ["review-star"])

        await makeKit().submitSurveyResponse(
            surveyId: form.id,
            response: SurveyResponse(results: [
                "nps": .npsRating(2),
                "plain-star": .symbolRating(1),
                "review-star": .symbolRating(4),
            ]),
            storeReviewQuestionIds: form.storeReviewQuestionIds
        )
        #expect(requester.requestCount == 1)
    }

    @Test("A submission that took too long does not ask and keeps the version unused")
    func staleSubmission() async {
        let followUp = StoreReviewFollowUp(
            requester: requester, storage: storage, appVersion: { "1.0" }, delay: .zero, maximumWait: .seconds(10)
        )
        await followUp.handleSubmission(
            SurveyResponse(results: ["q1": .symbolRating(5)]),
            storeReviewQuestionIds: ["q1"],
            submittedAt: ContinuousClock.now - .seconds(11),
            isMocked: false
        )
        #expect(requester.requestCount == 0)
        #expect(storage.lastRequestedAppVersion == nil)
    }

    @Test("A high rating on a star question without the flag does not count")
    func otherQuestionHighRating() {
        let response = SurveyResponse(results: ["plain-star": .symbolRating(5), "review-star": .symbolRating(3)])
        #expect(!StoreReviewFollowUp.qualifies(response, storeReviewQuestionIds: ["review-star"]))
    }

    @Test("Toasts expose their store-review question")
    func toastIds() {
        let toast = ToastTemplate(id: "t1", title: nil, description: nil, followUpIdentifier: nil,
                                  survey: star("q1", opensStoreReview: true))
        #expect(toast.storeReviewQuestionIds == ["q1"])
        let empty = ToastTemplate(id: "t2", title: nil, description: nil, followUpIdentifier: nil, survey: nil)
        #expect(empty.storeReviewQuestionIds.isEmpty)
    }

    @Test("The version is stored in UserDefaults under the WhiskrKit prefix")
    func userDefaultsStorage() {
        let suite = "StoreReviewStorageTests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let storage = UserDefaultsStoreReviewStorage(userDefaults: defaults)
        #expect(storage.lastRequestedAppVersion == nil)
        storage.lastRequestedAppVersion = "2.0"
        #expect(defaults.string(forKey: "eu.WhiskrKit.storeReviewRequestedAppVersion") == "2.0")
        #expect(UserDefaultsStoreReviewStorage(userDefaults: defaults).lastRequestedAppVersion == "2.0")
    }
}

@Suite("opensStoreReview decoding")
struct OpensStoreReviewDecodingTests {
    static let cases: [(label: String, value: String?, expected: Bool)] = [
        ("true", "true", true),
        ("false", "false", false),
        ("missing", nil, false),
        ("null", "null", false),
        ("string", #""yes""#, false),
        ("number", "1", false),
        ("object", "{}", false),
    ]

    @Test("Star question in a sheet", arguments: cases)
    func decodes(_ testCase: (label: String, value: String?, expected: Bool)) throws {
        let extra = testCase.value.map { #", "opensStoreReview": \#($0)"# } ?? ""
        let json = #"""
        { "template": "sheet", "id": "s1", "title": "Hi",
          "survey": { "template": "symbolRating", "id": "q1", "isRequired": false\#(extra) } }
        """#
        let survey = try JSONDecoder().decode(SurveyTemplate.self, from: Data(json.utf8))
        guard case .sheet(let base) = survey.presentationBase,
              case .symbolRating(let star) = base.survey.surveyBase else {
            Issue.record("Expected a sheet with a star question (\(testCase.label))")
            return
        }
        #expect(star.opensStoreReview == testCase.expected, "\(testCase.label)")
        #expect(base.storeReviewQuestionIds == (testCase.expected ? ["q1"] : []))
    }
}
