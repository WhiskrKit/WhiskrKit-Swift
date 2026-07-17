//
//  LocalServerE2ETests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//
//  End-to-end round trip against a locally running whiskrkit-server
//  (branch `survey-dismissal-tracking`), exercising the real SDK stack —
//  NetworkService, WhiskrKitEligibilityService, UserDefaultsEligibilityStorage —
//  over real HTTP. Skipped automatically when no server is listening.
//
//  Server prerequisites (see whiskrkit-server repo):
//  - Postgres + Redis up, `.build/debug/WhiskrkitServer serve` on :8080
//  - survey `test-survey`: repeatPolicy `once`, active, sampleRate 1.0
//  - API key `wk_test_e2e-verification-key`
//

import Testing
import Foundation
@testable import WhiskrKit

private enum LocalServer {
    static let baseURL = URL(string: "http://127.0.0.1:8080")!
    static let apiKey = "wk_test_e2e-verification-key"
    static let surveyId = "test-survey"

    static let isReachable: Bool = {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/survey/\(surveyId)"))
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 2

        let semaphore = DispatchSemaphore(value: 0)
        var reachable = false
        URLSession.shared.dataTask(with: request) { _, response, _ in
            reachable = (response as? HTTPURLResponse)?.statusCode == 200
            semaphore.signal()
        }.resume()
        semaphore.wait()
        return reachable
    }()
}

@Suite("Local Server E2E", .enabled(if: LocalServer.isReachable))
@MainActor
struct LocalServerE2ETests {

    /// A fresh device per run: unique UserDefaults suite, unique deviceId.
    private func makeStack() -> (WhiskrKitEligibilityService, EligibilityStorage, NetworkService) {
        let defaults = UserDefaults(suiteName: "e2e-\(UUID().uuidString)")!
        let storage = UserDefaultsEligibilityStorage(userDefaults: defaults)
        storage.initializeIfNeeded()
        storage.incrementSessionCount()

        let network = NetworkService(baseURL: LocalServer.baseURL)
        network.configure(apiKey: LocalServer.apiKey)

        return (WhiskrKitEligibilityService(networkService: network, storage: storage), storage, network)
    }

    /// The bug this whole change exists to fix, end to end: a dismissed survey
    /// must not be granted again.
    @Test("Dismissal round trip: grant, dismiss, then declined for ~30 days")
    func dismissalRoundTrip() async throws {
        let (service, storage, network) = makeStack()

        // 1. Fresh device: server grants.
        let granted = await service.checkEligibility(for: LocalServer.surveyId)
        #expect(granted != nil, "fresh device should be granted the 100%-targeted survey")

        // 2. Survey goes on screen: seen record + shown impression
        //    (what the impression modifier does on display).
        var seen = storage.seenSurveys
        seen[LocalServer.surveyId] = Date()
        storage.seenSurveys = seen
        try await network.recordImpression(surveyId: LocalServer.surveyId, event: .shown, trigger: .targeted)

        // 3. User dismisses without submitting: dismissed impression, nothing else.
        try await network.recordImpression(surveyId: LocalServer.surveyId, event: .dismissed, trigger: .targeted)

        // 4. Next check: the context now carries seenSurveys, so the `.once`
        //    policy must decline and hand back a finite ~30 day nextCheckAfter.
        let afterDismissal = await service.checkEligibility(for: LocalServer.surveyId)
        #expect(afterDismissal == nil, "dismissed .once survey must not be granted again")

        let nextCheck = try #require(storage.nextCheckAfter(for: LocalServer.surveyId))
        let days = nextCheck.timeIntervalSinceNow / 86_400
        #expect(days > 29 && days < 31, "expected ~30 day cooldown, got \(days) days")
        #expect(nextCheck < Date.distantFuture, "must be finite so the server stays reachable")

        // 5. Third check is suppressed client-side by the cached nextCheckAfter —
        //    no network call at all until the window passes.
        let suppressed = await service.checkEligibility(for: LocalServer.surveyId)
        #expect(suppressed == nil)
    }

    @Test("Completion still declines via completedSurveys alone")
    func completionRoundTrip() async throws {
        let (service, storage, _) = makeStack()

        let granted = await service.checkEligibility(for: LocalServer.surveyId)
        #expect(granted != nil)

        // Simulate what a successful submit records.
        var completed = storage.completedSurveys
        completed[LocalServer.surveyId] = Date()
        storage.completedSurveys = completed

        let afterCompletion = await service.checkEligibility(for: LocalServer.surveyId)
        #expect(afterCompletion == nil, "completed .once survey must not be granted again")
    }

    @Test("Impression endpoint accepts both events and rejects an unknown one")
    func impressionEndpointContract() async throws {
        let (_, _, network) = makeStack()

        try await network.recordImpression(surveyId: LocalServer.surveyId, event: .shown, trigger: .manual)
        try await network.recordImpression(surveyId: LocalServer.surveyId, event: .dismissed, trigger: .manual)

        // Unknown survey → 404, surfaced as a typed error and never retried.
        await #expect(throws: WhiskrKitError.self) {
            try await network.recordImpression(surveyId: "no-such-survey", event: .shown, trigger: .manual)
        }
    }
}
