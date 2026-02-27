//
//  EligibilityTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Testing
import Foundation
@testable import WhiskrKit

// MARK: - Mock Eligibility Storage

final class MockEligibilityStorage: EligibilityStorage {
    var _deviceId: String
    var _sessionCount: Int
    var _installDate: Date
    var lastSurveyDate: Date?
    private var _nextCheckAfter: [String: Date] = [:]

    var initializeCallCount = 0
    var incrementCallCount = 0

    init(
        deviceId: String = UUID().uuidString,
        sessionCount: Int = 1,
        installDate: Date = Date()
    ) {
        _deviceId = deviceId
        _sessionCount = sessionCount
        _installDate = installDate
    }

    var deviceId: String { _deviceId }
    var sessionCount: Int { _sessionCount }
    var installDate: Date { _installDate }

    func nextCheckAfter(for surveyId: String) -> Date? {
        _nextCheckAfter[surveyId]
    }

    func setNextCheckAfter(_ date: Date?, for surveyId: String) {
        _nextCheckAfter[surveyId] = date
    }

    func incrementSessionCount() {
        incrementCallCount += 1
        _sessionCount += 1
    }

    func initializeIfNeeded() {
        initializeCallCount += 1
    }
}

// MARK: - Mock Network Service for Eligibility

final class MockEligibilityNetworkService: NetworkService {
    var eligibilityResult: Result<SurveyEligibilityResponse, Error>?
    var eligibilityCallCount = 0
    var lastSurveyIdChecked: String?
    /// Optional delay in nanoseconds added before returning, useful for concurrency tests.
    var delayNanoseconds: UInt64 = 0

    init() {
        super.init(baseURL: URL(string: "https://test.example.com")!)
    }

    override func checkEligibility(
        surveyId: String,
        context: SurveyEligibilityContext
    ) async throws -> SurveyEligibilityResponse {
        eligibilityCallCount += 1
        lastSurveyIdChecked = surveyId

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch eligibilityResult {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        case nil:
            throw WhiskrKitError.notFound
        }
    }
}

// MARK: - UserDefaults Storage Tests

@Suite("Eligibility Storage Tests")
struct EligibilityStorageTests {

    var sut: UserDefaultsEligibilityStorage {
        UserDefaultsEligibilityStorage(userDefaults: makeFreshUserDefaults())
    }

    private func makeFreshUserDefaults() -> UserDefaults {
        let suiteName = "eu.WhiskrKitTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }

    @Test("First initialization sets deviceId, installDate, and sessionCount starts at 0")
    func firstInitializationSetsRequiredValues() {
        let defaults = makeFreshUserDefaults()
        let storage = UserDefaultsEligibilityStorage(userDefaults: defaults)

        // Before initializeIfNeeded, deviceId should be empty
        #expect(storage.deviceId == "")
        #expect(storage.sessionCount == 0)

        storage.initializeIfNeeded()

        #expect(storage.deviceId.isEmpty == false)
        #expect(storage.installDate <= Date())
    }

    @Test("initializeIfNeeded does not overwrite existing deviceId or installDate")
    func initializeIfNeededIsIdempotent() {
        let defaults = makeFreshUserDefaults()
        let storage = UserDefaultsEligibilityStorage(userDefaults: defaults)

        storage.initializeIfNeeded()
        let firstDeviceId = storage.deviceId
        let firstInstallDate = storage.installDate

        storage.initializeIfNeeded()

        #expect(storage.deviceId == firstDeviceId)
        #expect(storage.installDate == firstInstallDate)
    }

    @Test("incrementSessionCount increments from 0 to 1 on first call")
    func incrementSessionCountFirstCall() {
        let storage = sut
        storage.incrementSessionCount()
        #expect(storage.sessionCount == 1)
    }

    @Test("incrementSessionCount accumulates correctly across multiple calls")
    func incrementSessionCountMultipleCalls() {
        let storage = sut
        storage.incrementSessionCount()
        storage.incrementSessionCount()
        storage.incrementSessionCount()
        #expect(storage.sessionCount == 3)
    }

    @Test("deviceId is stable across multiple storage instances sharing the same UserDefaults")
    func deviceIdIsStableAcrossInstances() {
        let defaults = makeFreshUserDefaults()
        let first = UserDefaultsEligibilityStorage(userDefaults: defaults)
        first.initializeIfNeeded()
        let savedId = first.deviceId

        let second = UserDefaultsEligibilityStorage(userDefaults: defaults)
        #expect(second.deviceId == savedId)
    }

    @Test("lastSurveyDate is nil initially and can be set")
    func lastSurveyDate() {
        let storage = sut
        #expect(storage.lastSurveyDate == nil)

        let now = Date()
        storage.lastSurveyDate = now
        #expect(storage.lastSurveyDate != nil)
    }

    @Test("nextCheckAfter returns nil by default and persists correctly")
    func nextCheckAfterPersistsPerSurveyId() {
        let storage = sut
        #expect(storage.nextCheckAfter(for: "checkout-feedback") == nil)

        let future = Date().addingTimeInterval(3600)
        storage.setNextCheckAfter(future, for: "checkout-feedback")

        let retrieved = storage.nextCheckAfter(for: "checkout-feedback")
        #expect(retrieved != nil)
        #expect(abs(retrieved!.timeIntervalSince(future)) < 1)
    }

    @Test("nextCheckAfter is keyed per survey ID")
    func nextCheckAfterIsKeyedPerSurveyId() {
        let storage = sut
        let future = Date().addingTimeInterval(3600)
        storage.setNextCheckAfter(future, for: "survey-a")

        #expect(storage.nextCheckAfter(for: "survey-a") != nil)
        #expect(storage.nextCheckAfter(for: "survey-b") == nil)
    }

    @Test("setNextCheckAfter with nil clears the value")
    func setNextCheckAfterWithNilClears() {
        let storage = sut
        let future = Date().addingTimeInterval(3600)
        storage.setNextCheckAfter(future, for: "my-survey")
        storage.setNextCheckAfter(nil, for: "my-survey")
        #expect(storage.nextCheckAfter(for: "my-survey") == nil)
    }
}

// MARK: - Eligibility Service Tests

@Suite("Eligibility Service Tests")
@MainActor
struct EligibilityServiceTests {

    private func makeSUT(
        network: MockEligibilityNetworkService = MockEligibilityNetworkService(),
        storage: MockEligibilityStorage = MockEligibilityStorage()
    ) -> (EligibilityService, MockEligibilityNetworkService, MockEligibilityStorage) {
        let service = EligibilityService(networkService: network, storage: storage)
        return (service, network, storage)
    }

    private func makeToastSurveyTemplate() -> SurveyTemplate {
        SurveyTemplate(presentationBase: .toast(base: ToastTemplate(
            id: "test-toast",
            title: "Test",
            description: nil,
            followUpIdentifier: nil,
            survey: nil
        )))
    }

    @Test("When nextCheckAfter is in the future, no network call is made")
    func skipsNetworkCallWhenCacheIsValid() async {
        let (sut, network, storage) = makeSUT()
        let future = Date().addingTimeInterval(3600)
        storage.setNextCheckAfter(future, for: "checkout-feedback")

        let result = await sut.checkEligibility(for: "checkout-feedback")

        #expect(result == nil)
        #expect(network.eligibilityCallCount == 0)
    }

    @Test("When nextCheckAfter is in the past, a network call IS made")
    func makesNetworkCallWhenCacheIsExpired() async {
        let (sut, network, storage) = makeSUT()
        let past = Date().addingTimeInterval(-3600)
        storage.setNextCheckAfter(past, for: "checkout-feedback")

        let response = SurveyEligibilityResponse(shouldShow: false, survey: nil, nextCheckAfter: nil)
        network.eligibilityResult = .success(response)

        _ = await sut.checkEligibility(for: "checkout-feedback")

        #expect(network.eligibilityCallCount == 1)
    }

    @Test("When server returns shouldShow true, survey template is returned and lastSurveyDate is updated")
    func returnsSurveyWhenShouldShowIsTrue() async {
        let (sut, network, storage) = makeSUT()
        let template = makeToastSurveyTemplate()
        let future = Date().addingTimeInterval(86400)
        let response = SurveyEligibilityResponse(shouldShow: true, survey: template, nextCheckAfter: future)
        network.eligibilityResult = .success(response)

        let result = await sut.checkEligibility(for: "checkout-feedback")

        #expect(result != nil)
        #expect(storage.lastSurveyDate != nil)
    }

    @Test("When server returns shouldShow false, nil is returned and lastSurveyDate is NOT updated")
    func returnsNilWhenShouldShowIsFalse() async {
        let (sut, network, storage) = makeSUT()
        let response = SurveyEligibilityResponse(shouldShow: false, survey: nil, nextCheckAfter: nil)
        network.eligibilityResult = .success(response)

        let result = await sut.checkEligibility(for: "checkout-feedback")

        #expect(result == nil)
        #expect(storage.lastSurveyDate == nil)
    }

    @Test("nextCheckAfter from response is persisted per survey ID")
    func persistsNextCheckAfterFromResponse() async {
        let (sut, network, storage) = makeSUT()
        let nextCheck = Date().addingTimeInterval(7200)
        let response = SurveyEligibilityResponse(shouldShow: false, survey: nil, nextCheckAfter: nextCheck)
        network.eligibilityResult = .success(response)

        _ = await sut.checkEligibility(for: "checkout-feedback")

        let stored = storage.nextCheckAfter(for: "checkout-feedback")
        #expect(stored != nil)
        #expect(abs(stored!.timeIntervalSince(nextCheck)) < 1)
    }

    @Test("Network errors are handled gracefully — nil is returned, no crash")
    func networkErrorsAreHandledGracefully() async {
        let (sut, network, _) = makeSUT()
        network.eligibilityResult = .failure(WhiskrKitError.networkError(NSError(domain: "test", code: -1)))

        let result = await sut.checkEligibility(for: "checkout-feedback")

        #expect(result == nil)
    }

    @Test("Concurrent eligibility checks for the same survey ID are deduplicated")
    func deduplicatesConcurrentChecksForSameSurveyId() async {
        let (sut, network, _) = makeSUT()

        // Add a delay so the second task can observe the first as in-flight at the await point
        network.delayNanoseconds = 100_000_000 // 100 ms
        let template = makeToastSurveyTemplate()
        let response = SurveyEligibilityResponse(shouldShow: true, survey: template, nextCheckAfter: nil)
        network.eligibilityResult = .success(response)

        // Both tasks run on @MainActor and interleave at the await point inside checkEligibility.
        // The second task will see "checkout-feedback" in inFlightSurveyIds and return nil immediately.
        async let first = sut.checkEligibility(for: "checkout-feedback")
        async let second = sut.checkEligibility(for: "checkout-feedback")

        _ = await (first, second)

        // Only one network call should have been made
        #expect(network.eligibilityCallCount == 1)
    }
}

// MARK: - SurveyEligibilityContext Encoding Tests

@Suite("SurveyEligibilityContext Encoding Tests")
struct SurveyEligibilityContextTests {

    @Test("SurveyEligibilityContext encodes to valid JSON with ISO 8601 dates")
    func encodesWithISO8601Dates() throws {
        let installDate = Date(timeIntervalSince1970: 1_700_000_000)
        let context = SurveyEligibilityContext(
            deviceId: "test-device-id",
            appVersion: "1.0.0",
            locale: "en-US",
            sessionCount: 3,
            installDate: installDate,
            lastSurveyDate: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["deviceId"] as? String == "test-device-id")
        #expect(json["appVersion"] as? String == "1.0.0")
        #expect(json["locale"] as? String == "en-US")
        #expect(json["sessionCount"] as? Int == 3)
        #expect(json["installDate"] as? String != nil)
        #expect(json["lastSurveyDate"] == nil)
    }

    @Test("SurveyEligibilityContext encodes lastSurveyDate when present")
    func encodesLastSurveyDateWhenPresent() throws {
        let context = SurveyEligibilityContext(
            deviceId: "abc",
            appVersion: "2.0",
            locale: "nl-NL",
            sessionCount: 1,
            installDate: Date(),
            lastSurveyDate: Date(timeIntervalSince1970: 1_710_000_000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(context)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["lastSurveyDate"] as? String != nil)
    }

    @Test("SurveyEligibilityContext round-trips correctly through Codable")
    func roundTripsCorrectly() throws {
        let original = SurveyEligibilityContext(
            deviceId: "round-trip-id",
            appVersion: "1.5",
            locale: "de-DE",
            sessionCount: 7,
            installDate: Date(timeIntervalSince1970: 1_700_000_000),
            lastSurveyDate: Date(timeIntervalSince1970: 1_705_000_000)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SurveyEligibilityContext.self, from: data)

        #expect(decoded.deviceId == original.deviceId)
        #expect(decoded.appVersion == original.appVersion)
        #expect(decoded.locale == original.locale)
        #expect(decoded.sessionCount == original.sessionCount)
        #expect(abs(decoded.installDate.timeIntervalSince(original.installDate)) < 1)
        #expect(abs(decoded.lastSurveyDate!.timeIntervalSince(original.lastSurveyDate!)) < 1)
    }
}

// MARK: - SurveyEligibilityResponse Decoding Tests

@Suite("SurveyEligibilityResponse Decoding Tests")
struct SurveyEligibilityResponseTests {

    @Test("Decodes shouldShow true with nil nextCheckAfter")
    func decodesShouldShowTrueWithNilNextCheckAfter() throws {
        let json = """
        { "shouldShow": true, "survey": null, "nextCheckAfter": null }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(SurveyEligibilityResponse.self, from: Data(json.utf8))

        #expect(response.shouldShow == true)
        #expect(response.survey == nil)
        #expect(response.nextCheckAfter == nil)
    }

    @Test("Decodes shouldShow false with a nextCheckAfter date")
    func decodesShouldShowFalseWithNextCheckAfter() throws {
        let json = """
        { "shouldShow": false, "survey": null, "nextCheckAfter": "2026-01-01T00:00:00Z" }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(SurveyEligibilityResponse.self, from: Data(json.utf8))

        #expect(response.shouldShow == false)
        #expect(response.nextCheckAfter != nil)
    }
}
