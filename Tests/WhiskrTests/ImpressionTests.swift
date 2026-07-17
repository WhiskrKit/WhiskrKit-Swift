//
//  ImpressionTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Testing
import Foundation
@testable import WhiskrKit

// MARK: - Wire Format

@Suite("Survey Impression Wire Format Tests")
struct SurveyImpressionWireFormatTests {

    @Test("shown encodes to the exact string the endpoint expects")
    func shownEncodesExactly() throws {
        let data = try JSONEncoder().encode(SurveyImpressionRequest(event: .shown, trigger: .targeted))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["event"] as? String == "shown")
        #expect(json["trigger"] as? String == "targeted")
    }

    @Test("dismissed encodes to the exact string the endpoint expects")
    func dismissedEncodesExactly() throws {
        let data = try JSONEncoder().encode(SurveyImpressionRequest(event: .dismissed, trigger: .manual))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json["event"] as? String == "dismissed")
        #expect(json["trigger"] as? String == "manual")
    }

    @Test("The body carries the event and trigger and nothing else")
    func bodyCarriesOnlyEventAndTrigger() throws {
        let data = try JSONEncoder().encode(SurveyImpressionRequest(event: .shown, trigger: .targeted))
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(json.count == 2)
    }
}

// MARK: - Reporting

@Suite("Survey Impression Reporting Tests")
@MainActor
struct SurveyImpressionReportingTests {

    @Test("Reports the event and survey id to the network service")
    func reportsEventToNetwork() async {
        let network = MockNetworkService()
        let sut = WhiskrKitConfigurationService(networkService: network)

        await sut.recordImpression(surveyId: "your-journey-stats", event: .dismissed, trigger: .targeted)

        #expect(network.impressionCallCount == 1)
        #expect(network.lastImpressionSurveyId == "your-journey-stats")
        #expect(network.lastImpressionEvent == .dismissed)
        #expect(network.lastImpressionTrigger == .targeted)
    }

    /// Analytics must never break UX: a failed impression is swallowed, so a
    /// survey still shows and still submits when the endpoint is down.
    @Test("A failed impression is swallowed rather than thrown")
    func failedImpressionIsSwallowed() async {
        let network = MockNetworkService()
        network.shouldFail = true
        let sut = WhiskrKitConfigurationService(networkService: network)

        await sut.recordImpression(surveyId: "your-journey-stats", event: .shown, trigger: .manual)

        #expect(network.impressionCallCount == 1)
    }

    /// Unlike a submission, an impression is never queued: a retry would land in
    /// the wrong day's totals.
    @Test("A failed impression is not queued for retry")
    func failedImpressionIsNotQueued() async {
        let network = MockNetworkService()
        network.shouldFail = true
        let storage = MockSubmissionStorage()
        let sut = WhiskrKitConfigurationService(
            networkService: network,
            submissionQueue: SubmissionQueue(storage: storage)
        )

        await sut.recordImpression(surveyId: "your-journey-stats", event: .shown, trigger: .manual)

        #expect(storage.storedSubmissions.isEmpty)
    }
}
