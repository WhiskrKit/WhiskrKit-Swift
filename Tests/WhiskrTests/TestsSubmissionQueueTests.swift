//
//  SubmissionQueueTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@Suite("Submission Queue Tests")
struct SubmissionQueueTests {
    
    // MARK: - Enqueue Tests
    
    @Test("Queue enqueues submission")
    func enqueueSubmission() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        #expect(queue.count == 1)
        #expect(storage.saveCallCount == 1)
    }
    
    @Test("Queue replaces duplicate survey IDs")
    func replaceDuplicateSurveyIds() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        let submission1 = createTestSubmission(surveyId: "test-1")
        let submission2 = createTestSubmission(surveyId: "test-1")
        
        queue.enqueue(submission1)
        queue.enqueue(submission2)
        
        // Should only have 1 submission
        #expect(queue.count == 1)
        
        // Should have the second submission
        let retryable = queue.getRetryableSubmissions()
        #expect(retryable.first?.id == submission2.id)
    }
    
    @Test("Queue respects max size")
    func respectsMaxQueueSize() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        // Add more than max size (5)
        for i in 1...6 {
            let submission = createTestSubmission(surveyId: "test-\(i)")
            queue.enqueue(submission)
        }
        
        // Should only keep the max size
        #expect(queue.count == SubmissionQueueConfig.maxQueueSize)
        
        // Should have removed the first one
        let retryable = queue.getRetryableSubmissions()
        let surveyIds = retryable.map { $0.surveyId }
        #expect(!surveyIds.contains("test-1"))
        #expect(surveyIds.contains("test-6"))
    }
    
    // MARK: - Dequeue Tests
    
    @Test("Queue dequeues submission")
    func dequeueSubmission() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        #expect(queue.count == 1)
        
        queue.dequeue(submission)
        #expect(queue.count == 0)
        #expect(storage.saveCallCount == 2) // Once for enqueue, once for dequeue
    }
    
    // MARK: - Retry Count Tests
    
    @Test("Queue increments retry count")
    func incrementRetryCount() throws {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        queue.incrementRetryCount(for: submission)
        
        // Use getSubmission instead of getRetryableSubmissions
        // because the submission won't be retryable immediately due to throttling
        let updated = try #require(queue.getSubmission(id: submission.id))
        #expect(updated.retryCount == 1)
    }
    
    // MARK: - Retryable Submissions Tests
    
    @Test("Queue returns retryable submissions")
    func getRetryableSubmissions() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        let retryable = queue.getRetryableSubmissions()
        #expect(retryable.count == 1)
        #expect(retryable.first?.surveyId == "test-1")
    }
    
    @Test("Queue excludes expired submissions from retryable")
    func excludeExpiredSubmissions() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        // Create an expired submission
        var submission = createTestSubmission(surveyId: "test-1")
        submission = PendingSubmission(
            surveyId: submission.surveyId,
            response: submission.response,
            expirationDays: -10
        )
        queue.enqueue(submission)
        
        let retryable = queue.getRetryableSubmissions()
        #expect(retryable.isEmpty)
        
        // Queue should clean up expired
        #expect(queue.count == 0)
    }
    
    // MARK: - Clear Tests
    
    @Test("Queue clears all submissions")
    func clearQueue() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        for i in 1...3 {
            let submission = createTestSubmission(surveyId: "test-\(i)")
            queue.enqueue(submission)
        }
        
        #expect(queue.count == 3)
        
        queue.clear()
        #expect(queue.count == 0)
        #expect(storage.saveCallCount == 4) // 3 enqueues + 1 clear
    }
    
    // MARK: - Persistence Tests
    
    @Test("Queue loads from storage on init")
    func loadFromStorageOnInit() {
        let storage = MockSubmissionStorage()
        
        // Simulate existing submissions in storage
        let existingSubmissions = [
            createTestSubmission(surveyId: "test-1"),
            createTestSubmission(surveyId: "test-2")
        ]
        storage.storedSubmissions = existingSubmissions
        
        let queue = SubmissionQueue(storage: storage)
        
        #expect(queue.count == 2)
        #expect(storage.loadCallCount == 1)
    }
    
    @Test("Queue persists after enqueue")
    func persistAfterEnqueue() {
        let storage = MockSubmissionStorage()
        let queue = SubmissionQueue(storage: storage)
        
        let submission = createTestSubmission(surveyId: "test-1")
        queue.enqueue(submission)
        
        #expect(storage.saveCallCount == 1)
        #expect(storage.lastSavedSubmissions?.count == 1)
    }
}

// MARK: - Helper Functions

private func createTestSubmission(surveyId: String) -> PendingSubmission {
    let response = SurveyResponse(
        results: ["q1": .symbolRating(5)]
    )
    return PendingSubmission(surveyId: surveyId, response: response)
}

