//
//  TextSurveyTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct TextSurveyTemplate: Decodable {
    let id: String
    let title: String?
    let description: String?
    let maxLength: Int?
    let isRequired: Bool
    let A11yLabel: String?
    let a11yHint: String?
    
    init(
        id: String,
        title: String?,
        description: String?,
        maxLength: Int = 200,
        isRequired: Bool,
        A11yLabel: String?,
        a11yHint: String?
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.maxLength = maxLength
        self.isRequired = isRequired
        self.A11yLabel = A11yLabel
        self.a11yHint = a11yHint
    }
    
    enum CodingKeys: CodingKey {
        case id
        case title
        case description
        case maxLength
        case isRequired
        case A11yLabel
        case a11yHint
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.maxLength = try container.decodeIfPresent(Int.self, forKey: .maxLength)
        self.isRequired = try container.decode(Bool.self, forKey: .isRequired)
        self.A11yLabel = try container.decodeIfPresent(String.self, forKey: .A11yLabel)
        self.a11yHint = try container.decodeIfPresent(String.self, forKey: .a11yHint)
    }
}
