//
//  StoreReviewQuestionIds.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

// The ids of the star questions that may lead to the App Store review prompt.
// A response's results are keyed by these same question ids.

extension SurveyPresentation {
    /// This question's id when it is a star question with `opensStoreReview` on.
    var storeReviewQuestionId: String? {
        if case .symbolRating(let base) = surveyBase, base.opensStoreReview {
            return base.id
        }
        return nil
    }
}

extension SheetTemplate {
    var storeReviewQuestionIds: Set<String> {
        Set([survey.storeReviewQuestionId].compactMap { $0 })
    }
}

extension ToastTemplate {
    var storeReviewQuestionIds: Set<String> {
        Set([survey?.storeReviewQuestionId].compactMap { $0 })
    }
}

extension FullScreenFormTemplate {
    var storeReviewQuestionIds: Set<String> {
        Set(surveys.compactMap(\.storeReviewQuestionId))
    }
}
