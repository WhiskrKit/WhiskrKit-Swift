//
//  SurveyEligibilityResponse.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SurveyEligibilityResponse: Decodable {
    let shouldShow: Bool
    let survey: SurveyTemplate?
    let nextCheckAfter: Date?
    let removeFromHistory: Bool?
}
