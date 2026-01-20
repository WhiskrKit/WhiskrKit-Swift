//
//  ThumbsSurveyTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct ThumbsSurveyTemplate: Decodable {
    let id: String
    let title: String?
    let subtitle: String?
    let isRequired: Bool
    let A11yLabel: String?
    let A11yHint: String?
}
