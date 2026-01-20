//
//  SubmissionQueue.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

final class SubmissionQueue {
    private var submissions: [PendingSubmission] = []
    private let storage: SubmissionStorage
    
    init(storage: SubmissionStorage = UserDefaultsSubmissionStorage()) {
        self.storage = storage
        loadFromStorage()
    }
    
    // All methods are automatically thread-safe with actor
    func enqueue(_ submission: PendingSubmission) {
        submissions.removeAll { $0.surveyId == submission.surveyId }
        
        if submissions.count >= SubmissionQueueConfig.maxQueueSize {
            submissions.removeFirst()
        }
        
        submissions.append(submission)
        persist()
    }
    
    func dequeue(_ submission: PendingSubmission) {
        submissions.removeAll { $0.id == submission.id }
        persist()
    }
    
    func incrementRetryCount(for submission: PendingSubmission) {
        if let index = submissions.firstIndex(where: { $0.id == submission.id }) {
            submissions[index].incrementRetryCount()
            persist()
        }
    }
    
    func getRetryableSubmissions() -> [PendingSubmission] {
        cleanupExpired()
        return submissions.filter { $0.canRetryNow }
    }
    
    func getSubmission(id: UUID) -> PendingSubmission? {
        return submissions.first { $0.id == id }
    }
    
    var count: Int {
        submissions.count
    }
    
    func clear() {
        submissions.removeAll()
        persist()
    }
    
    // MARK: - Private Methods
    
    private func cleanupExpired() {
        let before = submissions.count
        submissions.removeAll { $0.isExpired }
        
        if before != submissions.count {
            persist()
        }
    }
    
    private func persist() {
        storage.save(submissions)
    }
    
    private func loadFromStorage() {
        submissions = storage.load()
        cleanupExpired()
    }
}
