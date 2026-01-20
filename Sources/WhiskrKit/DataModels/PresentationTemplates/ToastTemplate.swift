//
//  ToastTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct ToastTemplate: Decodable {
    let id: String
    let title: String?
    let description: String?
    let followUpIdentifier: String?
    let survey: SurveyPresentation?
}
