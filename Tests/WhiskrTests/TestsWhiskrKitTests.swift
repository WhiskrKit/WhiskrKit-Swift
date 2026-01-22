//
//  WhiskrKitTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@Suite("WhiskrKit Core Tests")
struct WhiskrKitCoreTests {
    
    // MARK: - Initialization Tests
    
    @Test("WhiskrKit initializes with API key")
    func initializeWithAPIKey() {
        let whiskrKit = WhiskrKit.shared
		whiskrKit.initialize(
			apiKey: "test-api-key",
			withMockedSurveys: true
		)
    }
    
    @Test("WhiskrKit sets theme correctly")
    func setsThemeCorrectly() {
        let whiskrKit = WhiskrKit.shared
        
        let customTheme = WhiskrKitTheme.systemStyle
        whiskrKit.setTheme(customTheme)
        
        #expect(whiskrKit.theme != nil)
    }
    
    // MARK: - Fetch Survey Tests
    
    @Test("WhiskrKit returns nil when fetching survey without initialization")
    func fetchSurveyWithoutInitialization() async {
        let whiskrKit = WhiskrKit.shared
        // Don't call initialize
        
        let result: MockSurveyTemplate? = await whiskrKit.fetchSurveyTemplate(for: "test")
        
        #expect(result == nil)
    }
    
    // MARK: - Submit Response Tests
    
    @Test("WhiskrKit submits survey response after initialization")
	func submitSurveyResponseAfterInitialization() async {
        let whiskrKit = WhiskrKit.shared
		whiskrKit.initialize(apiKey: "test-key",withMockedSurveys: true)

        let response = SurveyResponse(
            results: ["q1": .symbolRating(5)]
        )

        await whiskrKit.submitSurveyResponse(surveyId: "test", response: response)
    }
}

// MARK: - Configuration Service Tests

@Suite("Configuration Service Tests")
struct ConfigurationServiceTests {
    
    @Test("Configuration service configures with API key")
    func configuresWithAPIKey() {
        let mockNetwork = MockNetworkService()
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        
        let service = WhiskrKitConfigurationService(
            networkService: mockNetwork,
            submissionQueue: queue
        )
        
        service.configure(apiKey: "test-key")
    }
    
    @Test("Configuration service submits response successfully")
	func submitResponseSuccessfully() async {
        let mockNetwork = MockNetworkService()
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        
        let service = WhiskrKitConfigurationService(
            networkService: mockNetwork,
            submissionQueue: queue
        )
        service.configure(apiKey: "test-key")
        
        let response = SurveyResponse(
            results: ["q1": .symbolRating(5)]
        )
        
        await service.submitSurveyResponse(surveyId: "test", response: response)
        
        #expect(mockNetwork.submitCallCount == 1)
        #expect(queue.count == 0) // Should not be queued on success
    }
    
    @Test("Configuration service queues failed submissions")
	func queuesFailedSubmissions() async {
        let mockNetwork = MockNetworkService()
        mockNetwork.shouldFail = true
        
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        
        let service = WhiskrKitConfigurationService(
            networkService: mockNetwork,
            submissionQueue: queue
        )
        service.configure(apiKey: "test-key")
        
        let response = SurveyResponse(
            results: ["q1": .symbolRating(5)]
        )
        
        await service.submitSurveyResponse(surveyId: "test", response: response)
        
        // Should be added to queue on failure
        #expect(queue.count == 1)
    }
    
    @Test("Configuration service retries pending submissions on configure")
	func retriesPendingSubmissionsOnConfigure() async {
        let mockNetwork = MockNetworkService()
        let mockStorage = MockSubmissionStorage()
        
        // Pre-populate storage with a pending submission
        let existingSubmission = createTestSubmission(surveyId: "pending-1")
        mockStorage.storedSubmissions = [existingSubmission]
        
        let queue = SubmissionQueue(storage: mockStorage)
        
        let service = WhiskrKitConfigurationService(
            networkService: mockNetwork,
            submissionQueue: queue
        )
        
        #expect(queue.count == 1)
        
        // Configure should trigger retry
        service.configure(apiKey: "test-key")
        
        // Give async retry task time to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Pending submission should be retried and removed
        #expect(mockNetwork.submitCallCount >= 1)
    }
}

// MARK: - Helper Functions

private func createTestSubmission(surveyId: String) -> PendingSubmission {
    let response = SurveyResponse(
        results: ["q1": .symbolRating(5)]
    )
    return PendingSubmission(surveyId: surveyId, response: response)
}


