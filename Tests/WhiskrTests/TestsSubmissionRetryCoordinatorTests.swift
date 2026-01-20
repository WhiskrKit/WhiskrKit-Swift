//
//  SubmissionRetryCoordinatorTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@Suite("Submission Retry Coordinator Tests")
struct SubmissionRetryCoordinatorTests {
    
    // MARK: - Retry Success Tests
    
    @Test("Coordinator retries pending submissions successfully")
    func retriesPendingSubmissionsSuccessfully() async {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        // Add a pending submission
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        #expect(queue.count == 1)
        
        // Retry submissions
        await coordinator.retryPendingSubmissions()
        
        // Should be removed from queue on success
        #expect(queue.count == 0)
        #expect(mockNetwork.submitCallCount == 1)
    }
    
    @Test("Coordinator handles multiple pending submissions")
    func handlesMultiplePendingSubmissions() async {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        // Add multiple submissions
        for i in 1...3 {
            let submission = createTestSubmission(surveyId: "test-\(i)")
            queue.enqueue(submission)
        }
        
        #expect(queue.count == 3)
        
        await coordinator.retryPendingSubmissions()
        
        // All should be removed on success
        #expect(queue.count == 0)
        #expect(mockNetwork.submitCallCount == 3)
    }
    
    // MARK: - Retry Failure Tests
    
    @Test("Coordinator increments retry count on failure")
    func incrementsRetryCountOnFailure() async throws {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        mockNetwork.shouldFail = true
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        await coordinator.retryPendingSubmissions()
        
        // Should still be in queue
        #expect(queue.count == 1)
        
        // Get the updated submission directly by ID instead of using getRetryableSubmissions
        // which filters by retry throttle
        let updated = try #require(queue.getSubmission(id: submission.id))
        #expect(updated.retryCount == 1)
    }
    
    @Test("Coordinator removes submission after max retries exceeded")
    func removesSubmissionAfterMaxRetries() async {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        mockNetwork.shouldFail = true
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        // Create a submission that's already at maxRetries - 1
        // Use the DEBUG initializer to avoid throttling issues
        let response = SurveyResponse(
            surveyIdentifier: "test-1",
            results: ["q1": .symbolRating(score: 5)]
        )
        let submission = PendingSubmission(
            surveyId: "test-1",
            response: response,
            retryCount: SubmissionQueueConfig.maxRetries - 1,
            lastRetryAttempt: Date.distantPast // Set to past so it's retryable
        )
        queue.enqueue(submission)
        
        await coordinator.retryPendingSubmissions()
        
        // Should be removed after exceeding max retries
        #expect(queue.count == 0)
    }
    
    @Test("Coordinator skips if already retrying")
    func skipsIfAlreadyRetrying() async {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        mockNetwork.delaySeconds = 1.0 // Add delay to keep retry in progress
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        // Start first retry
        async let firstRetry: Void = coordinator.retryPendingSubmissions()
        
        // Try to start second retry while first is in progress
        await coordinator.retryPendingSubmissions()
        
        await firstRetry
        
        // Should only have called submit once
        #expect(mockNetwork.submitCallCount == 1)
    }
    
    // MARK: - Idempotency Tests
    
    @Test("Coordinator passes idempotency key to network service")
    func passesIdempotencyKey() async throws {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        await coordinator.retryPendingSubmissions()
        
        let capturedKey = try #require(mockNetwork.lastIdempotencyKey)
        #expect(capturedKey == submission.idempotencyKey.uuidString)
    }
    
    // MARK: - Empty Queue Tests
    
    @Test("Coordinator handles empty queue gracefully")
    func handlesEmptyQueueGracefully() async {
        let mockStorage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: mockStorage)
        let mockNetwork = MockNetworkService()
        
        let coordinator = SubmissionRetryCoordinator(queue: queue, networkService: mockNetwork)
        
        // No submissions in queue
        await coordinator.retryPendingSubmissions()
        
        #expect(mockNetwork.submitCallCount == 0)
    }
}

// MARK: - Helper Functions

private func createTestSubmission(surveyId: String) -> PendingSubmission {
    let response = SurveyResponse(
        surveyIdentifier: surveyId,
        results: ["q1": .symbolRating(score: 5)]
    )
    return PendingSubmission(surveyId: surveyId, response: response)
}


