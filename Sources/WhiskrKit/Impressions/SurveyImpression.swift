//
//  SurveyImpression.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// A survey's on-screen lifecycle event. `dismissed` means the survey left
/// the screen without a submission; a submit reports no second event.
enum SurveyImpressionEvent: String, Encodable {
    case shown
    case dismissed
}

/// How the survey came to be on screen.
enum SurveyImpressionTrigger: String, Encodable {
    /// Shown because the eligibility check granted it.
    case targeted
    /// The host app asked for it directly, bypassing targeting.
    case manual
}

struct SurveyImpressionRequest: Encodable {
    let event: SurveyImpressionEvent
    let trigger: SurveyImpressionTrigger
}
