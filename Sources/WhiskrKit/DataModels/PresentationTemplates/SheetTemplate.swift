//
//  SheetTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SheetTemplate: Decodable {
    let id: String
    let title: String?
    let description: String?
    let followUpQuestion: String?
    let survey: SurveyPresentation
}
