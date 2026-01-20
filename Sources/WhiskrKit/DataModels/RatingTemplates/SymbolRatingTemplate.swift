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
    let opensStoreReview: Bool // TODO: - Implement App Store opening
    //    let symbolType: SymbolType // TODO: - Offer different types of symbols to be shown
    let isRequired: Bool
    let A11yLabel: String?
    let A11yHint: String?
    
    enum SymbolType: Decodable {
        case star, heart, emoji
    }
}
