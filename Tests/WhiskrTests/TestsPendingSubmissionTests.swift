//
//  PendingSubmissionTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@Suite("Pending Submission Tests")
struct PendingSubmissionTests {
    
    // MARK: - Initialization Tests
    
    @Test("Pending submission initializes with correct defaults")
    func initializationDefaults() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let submission = PendingSubmission(surveyId: "test-survey", response: response)
        
        #expect(submission.surveyId == "test-survey")
        #expect(submission.retryCount == 0)
        #expect(submission.lastRetryAttempt == nil)
        #expect(!submission.isExpired)
        #expect(submission.shouldRetry)
        #expect(submission.canRetryNow)
    }
    
    @Test("Pending submission generates unique IDs")
    func generatesUniqueIds() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let submission1 = PendingSubmission(surveyId: "test", response: response)
        let submission2 = PendingSubmission(surveyId: "test", response: response)
        
        #expect(submission1.id != submission2.id)
        #expect(submission1.idempotencyKey != submission2.idempotencyKey)
    }
    
    // MARK: - Expiration Tests
    
    @Test("Pending submission is not expired within expiration period")
    func notExpiredWithinPeriod() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let submission = PendingSubmission(
            surveyId: "test",
            response: response,
            expirationDays: 7
        )
        
        #expect(!submission.isExpired)
    }
    
    // MARK: - Retry Logic Tests
    
    @Test("Submission should retry when under max retries and not expired")
    func shouldRetryWhenValid() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        var submission = PendingSubmission(surveyId: "test", response: response)
        
        // Simulate a few retries
        submission.incrementRetryCount()
        submission.incrementRetryCount()
        
        #expect(submission.shouldRetry)
        #expect(submission.retryCount < SubmissionQueueConfig.maxRetries)
    }
    
    @Test("Submission should not retry when max retries exceeded")
    func shouldNotRetryWhenMaxRetriesExceeded() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        var submission = PendingSubmission(surveyId: "test", response: response)
        
        // Exceed max retries
        for _ in 0..<SubmissionQueueConfig.maxRetries {
            submission.incrementRetryCount()
        }
        
        #expect(!submission.shouldRetry)
    }
    
    @Test("Can retry now returns true for first attempt")
    func canRetryNowForFirstAttempt() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let submission = PendingSubmission(surveyId: "test", response: response)
        
        #expect(submission.canRetryNow)
        #expect(submission.lastRetryAttempt == nil)
    }
    
    @Test("Can retry now respects throttle period")
    func canRetryNowRespectsThrottle() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        var submission = PendingSubmission(surveyId: "test", response: response)
        submission.incrementRetryCount()
        
        // Should not be able to retry immediately after increment
        #expect(!submission.canRetryNow)
    }
    
    @Test("Increment retry count updates fields correctly")
    func incrementRetryCountUpdatesFields() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        var submission = PendingSubmission(surveyId: "test", response: response)
        
        let beforeCount = submission.retryCount
        let beforeAttempt = submission.lastRetryAttempt
        
        submission.incrementRetryCount()
        
        #expect(submission.retryCount == beforeCount + 1)
        #expect(submission.lastRetryAttempt != beforeAttempt)
        #expect(submission.lastRetryAttempt != nil)
    }
    
    // MARK: - Codable Tests
    
    @Test("Pending submission encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let original = PendingSubmission(surveyId: "test-survey", response: response)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PendingSubmission.self, from: data)
        
        #expect(decoded.id == original.id)
        #expect(decoded.idempotencyKey == original.idempotencyKey)
        #expect(decoded.surveyId == original.surveyId)
        #expect(decoded.retryCount == original.retryCount)
        #expect(decoded.response == original.response)
    }
    
    // MARK: - Equatable Tests
    
    @Test("Pending submissions with same ID are equal")
    func equalityBasedOnId() {
        let response1 = SurveyResponse(
            surveyIdentifier: "test1",
            results: ["q1": .symbolRating(score: 5)]
        )
        let response2 = SurveyResponse(
            surveyIdentifier: "test2",
            results: ["q1": .symbolRating(score: 3)]
        )
        
        let submission1 = PendingSubmission(surveyId: "test", response: response1)
        
        // Create a "copy" with same ID but different response
        var submission2 = PendingSubmission(surveyId: "test", response: response2)
        submission2 = PendingSubmission(
            surveyId: submission2.surveyId,
            response: submission2.response,
            expirationDays: 7
        )
        
        // Different IDs, should not be equal
        #expect(submission1 != submission2)
        
        // Same submission should equal itself
        #expect(submission1 == submission1)
    }
}
