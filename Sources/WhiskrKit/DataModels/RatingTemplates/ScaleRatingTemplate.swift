//
//  ScaleRatingTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct ScaleRatingTemplate: Decodable {
    let id: String
    let title: String?
    let subtitle: String?
    let ratingRange: RatingRange
    let isRequired: Bool
    let A11yLabel: String?
    let A11yHint: String?

    struct RatingRange: Decodable {
        let min: Int
        let max: Int

        var asClosedRange: ClosedRange<Int> {
            min...max
        }
    }
}
