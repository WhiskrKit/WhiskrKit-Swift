//
//  PendingSubmission.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct PendingSubmission: Codable, Identifiable, Equatable {
    let id: UUID
    let idempotencyKey: UUID
    let surveyId: String
    let response: SurveyResponse
    let timestamp: Date
    let expiresAt: Date
    var retryCount: Int
    var lastRetryAttempt: Date?
    
    init(
        surveyId: String,
        response: SurveyResponse,
        expirationDays: Int = 7
    ) {
        self.id = UUID()
        self.idempotencyKey = UUID()
        self.surveyId = surveyId
        self.response = response
        self.timestamp = Date()
        self.expiresAt = Calendar.current.date(
            byAdding: .day,
            value: expirationDays,
            to: Date()
        ) ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        self.retryCount = 0
        self.lastRetryAttempt = nil
    }
    
    #if DEBUG
    /// Test-only initializer with full control over properties
    init(
        id: UUID = UUID(),
        idempotencyKey: UUID = UUID(),
        surveyId: String,
        response: SurveyResponse,
        timestamp: Date = Date(),
        expiresAt: Date? = nil,
        retryCount: Int = 0,
        lastRetryAttempt: Date? = nil
    ) {
        self.id = id
        self.idempotencyKey = idempotencyKey
        self.surveyId = surveyId
        self.response = response
        self.timestamp = timestamp
        self.expiresAt = expiresAt ?? Calendar.current.date(
            byAdding: .day,
            value: 7,
            to: Date()
        ) ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        self.retryCount = retryCount
        self.lastRetryAttempt = lastRetryAttempt
    }
    #endif
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var shouldRetry: Bool {
        !isExpired && retryCount < SubmissionQueueConfig.maxRetries
    }
    
    var canRetryNow: Bool {
        guard shouldRetry else { return false }
        
        // First attempt, always allow
        guard let lastRetry = lastRetryAttempt else { return true }
        
        // Throttle subsequent attempts
        let timeSinceLastRetry = Date().timeIntervalSince(lastRetry)
        return timeSinceLastRetry >= SubmissionQueueConfig.retryThrottle
    }
    
    mutating func incrementRetryCount() {
        retryCount += 1
        lastRetryAttempt = Date()
    }
    
    static func == (lhs: PendingSubmission, rhs: PendingSubmission) -> Bool {
        lhs.id == rhs.id
    }
}
