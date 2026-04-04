//
//  SubmissionRetryCoordinator.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog
import UIKit

@MainActor
final class SubmissionRetryCoordinator {
    private let queue: SubmissionQueue
    private let networkService: NetworkService
    private var isRetrying = false

    init(queue: SubmissionQueue, networkService: NetworkService) {
        self.queue = queue
        self.networkService = networkService

        setupAppLifecycleObservers()
    }

    // MARK: - Public Methods

    /// Retry all pending submissions
    func retryPendingSubmissions() async {
        guard !isRetrying else {
            Logger.wkCache.info("⏭️ Retry already in progress, skipping")
            return
        }

        isRetrying = true
        defer { isRetrying = false }

        let submissions = queue.getRetryableSubmissions()

        guard !submissions.isEmpty else {
            Logger.wkCache.info("📭 No submissions to retry")
            return
        }

        Logger.wkCache.info("🔄 Retrying \(submissions.count) pending submissions")

        for submission in submissions {
            await retrySubmission(submission)
        }
    }

    // MARK: - Private Methods

    private func retrySubmission(_ submission: PendingSubmission) async {
        do {
            try await networkService.submitRating(
                surveyId: submission.surveyId,
                identifier: "", // Could add to PendingSubmission if needed
                surveyResponse: submission.response,
                idempotencyKey: submission.idempotencyKey.uuidString // ← Pass to network
            )

            Logger.wkCache.info("✅ Retry succeeded: \(submission.surveyId)")
            queue.dequeue(submission)

        } catch {
            Logger.wkCache.warning("❌ Retry failed: \(submission.surveyId) - \(error)")
            
            // Increment retry count
            queue.incrementRetryCount(for: submission)
            
            // Get the updated submission to check current retry count
            guard let updatedSubmission = queue.getSubmission(id: submission.id) else {
                return
            }

            // Check if max retries exceeded
            if updatedSubmission.retryCount >= SubmissionQueueConfig.maxRetries {
                Logger.wkCache.warning("⚠️ Max retries exceeded, removing from queue: \(submission.surveyId)")
                queue.dequeue(submission)
            }
        }
    }

    private func setupAppLifecycleObservers() {
        // Retry when app enters foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.retryPendingSubmissions()
            }
        }
    }
}
