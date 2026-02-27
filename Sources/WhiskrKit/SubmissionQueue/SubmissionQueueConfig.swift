//
//  SubmissionQueueConfig.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

enum SubmissionQueueConfig {
    /// Maximum number of submissions to keep in queue
    static let maxQueueSize = 5
    
    /// Maximum retry attempts per submission
    static let maxRetries = 5
    
    /// Minimum time between retry attempts (5 minutes)
    static let retryThrottle: TimeInterval = 300
    
    /// Number of days before submissions expire
    static let expirationDays = 7
    
    /// UserDefaults key for persistence
    static let storageKey = "eu.WhiskrKit.pendingSubmissions"
}
