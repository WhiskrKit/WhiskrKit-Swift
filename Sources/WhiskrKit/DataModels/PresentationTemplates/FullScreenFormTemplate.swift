//
//  FullScreenFormTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct FullScreenFormTemplate: Decodable {
    let id: String
    let title: String?
    let subtitle: String?
    let description: String?
    let surveys: [SurveyPresentation]
}
