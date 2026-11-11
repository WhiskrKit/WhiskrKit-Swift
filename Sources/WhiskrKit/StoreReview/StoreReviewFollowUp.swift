//
//  StoreReviewFollowUp.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

/// Asks the OS for its App Store review prompt after a survey with a high star rating.
///
/// It fires only when all of these hold:
/// - the survey response was submitted successfully (a failed submission that is
///   queued for retry does not count, and dismissing without submitting never reaches here);
/// - a submitted star question has `opensStoreReview` switched on (per question, on the dashboard)
///   and was rated at least ``minimumRating``;
/// - no review was requested yet for the current app version (`CFBundleShortVersionString`).
///
/// The request is made after ``delay`` so it does not collide with the survey's
/// dismissal animation. iOS decides whether the prompt actually appears and throttles it further.
@MainActor
final class StoreReviewFollowUp {
    /// A star rating at or above this asks for a review.
    static let minimumRating = 4

    private let requester: any StoreReviewRequester
    private let storage: any StoreReviewStorage
    private let appVersion: () -> String?
    private let delay: Duration

    init(
        requester: any StoreReviewRequester = SystemStoreReviewRequester(),
        storage: any StoreReviewStorage = UserDefaultsStoreReviewStorage(),
        appVersion: @escaping () -> String? = { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String },
        delay: Duration = .milliseconds(700)
    ) {
        self.requester = requester
        self.storage = storage
        self.appVersion = appVersion
        self.delay = delay
    }

    /// True when a store-review star question in `questionIds` was rated at least ``minimumRating``.
    static func qualifies(_ response: SurveyResponse, storeReviewQuestionIds questionIds: Set<String>) -> Bool {
        questionIds.contains { id in
            if case .symbolRating(let score) = response.results[id] {
                return score >= minimumRating
            }
            return false
        }
    }

    /// Call only after a successful submission. In mock mode StoreKit is never called
    /// and nothing is persisted; the would-be request is logged instead.
    func handleSubmission(
        _ response: SurveyResponse,
        storeReviewQuestionIds questionIds: Set<String>,
        isMocked: Bool
    ) async {
        guard Self.qualifies(response, storeReviewQuestionIds: questionIds) else { return }

        if isMocked {
            try? await Task.sleep(for: delay)
            Logger.wkCore.info("⭐️ Mocked surveys: an App Store review would have been requested now.")
            return
        }

        let version = appVersion() ?? ""
        guard storage.lastRequestedAppVersion != version else {
            Logger.wkCore.info("⭐️ App Store review already requested for app version '\(version)'. Skipping.")
            return
        }

        try? await Task.sleep(for: delay)

        // Checked again: another survey may have asked while this one waited.
        guard storage.lastRequestedAppVersion != version else { return }
        if requester.requestReview() {
            storage.lastRequestedAppVersion = version
            Logger.wkCore.info("⭐️ Requested the App Store review prompt for app version '\(version)'.")
        }
    }
}
