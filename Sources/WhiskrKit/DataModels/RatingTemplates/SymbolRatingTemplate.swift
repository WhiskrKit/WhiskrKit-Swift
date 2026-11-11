//
//  StarRatingTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SymbolRatingTemplate: Decodable {
    let id: String
    let title: String?
    let description: String?
    /// Whether a high rating on this question is followed by the system App Store
    /// review prompt (see ``StoreReviewFollowUp``). Missing, `null` or a wrong type
    /// decodes as `false` and never fails the survey.
    let opensStoreReview: Bool
    //    let symbolType: SymbolType // TODO: - Offer different types of symbols to be shown
    let isRequired: Bool
    let A11yLabel: String?
    let A11yHint: String?

    enum SymbolType: Decodable {
        case star, heart, emoji
    }
}

extension SymbolRatingTemplate {
    private enum CodingKeys: String, CodingKey {
        case id, title, description, opensStoreReview, isRequired, A11yLabel, A11yHint
    }

    // In an extension so the memberwise initializer is kept.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        opensStoreReview = (try? container.decodeIfPresent(Bool.self, forKey: .opensStoreReview)) ?? false
        isRequired = try container.decode(Bool.self, forKey: .isRequired)
        A11yLabel = try container.decodeIfPresent(String.self, forKey: .A11yLabel)
        A11yHint = try container.decodeIfPresent(String.self, forKey: .A11yHint)
    }
}
