//
//  SurveyEligibilityContext.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SurveyEligibilityContext: Codable {
    let deviceId: String
    let appVersion: String
    let locale: String
    let sessionCount: Int
    let installDate: Date
    let lastSurveyDate: Date?
    let completedSurveys: [String: Date]
}
