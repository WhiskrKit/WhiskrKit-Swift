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
    /// Language the server served this survey in (e.g. "nl"); WhiskrKit's own strings follow it.
    var language: String? = nil
    /// Server-controlled "Powered by WhiskrKit" badge. Missing or malformed means hidden.
    var branding: Branding? = nil
}
