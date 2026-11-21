//
//  ScaleRatingTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct ScaleRatingTemplate: Decodable {
    let id: String
    let title: String?
    let subtitle: String?
    let ratingRange: RatingRange
    let isRequired: Bool
    let A11yLabel: String?
    let A11yHint: String?
    /// The metric the server calculates from the score. It sets the button colors
    /// and the default end labels; the SDK only sends the chosen number.
    var metric: Metric = .custom
    /// How the server asks for the scale to be shown. Use ``resolvedDisplayStyle``
    /// to render, which falls back to numbers when stars don't fit the range.
    var displayStyle: DisplayStyle = .numbers
    /// End labels for a `custom` metric; `nil` for the presets, which use the SDK's own.
    var minLabel: String? = nil
    var maxLabel: String? = nil

    struct RatingRange: Decodable, Equatable {
        let min: Int
        let max: Int

        var asClosedRange: ClosedRange<Int> {
            min...max
        }
    }

    /// Unknown values from a newer server decode as `.custom`.
    enum Metric: String, Equatable {
        case nps, csat, ces, custom
    }

    /// Unknown values from a newer server decode as `.numbers`.
    enum DisplayStyle: String, Equatable {
        case numbers, stars
    }

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, ratingRange, isRequired, A11yLabel, A11yHint
        case metric, displayStyle, minLabel, maxLabel
    }
}

extension ScaleRatingTemplate {
    // In an extension, so the memberwise initializer stays available.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        ratingRange = try container.decode(RatingRange.self, forKey: .ratingRange)
        isRequired = try container.decode(Bool.self, forKey: .isRequired)
        A11yLabel = try container.decodeIfPresent(String.self, forKey: .A11yLabel)
        A11yHint = try container.decodeIfPresent(String.self, forKey: .A11yHint)

        // The new fields are optional and lenient: an older server leaves them out,
        // a newer one may send values this SDK doesn't know. Neither may break the survey.
        func lenientString(_ key: CodingKeys) -> String? {
            (try? container.decodeIfPresent(String.self, forKey: key)) ?? nil
        }
        metric = lenientString(.metric).flatMap(Metric.init(rawValue:)) ?? .custom
        displayStyle = lenientString(.displayStyle).flatMap(DisplayStyle.init(rawValue:)) ?? .numbers
        minLabel = lenientString(.minLabel)
        maxLabel = lenientString(.maxLabel)
    }

    /// Stars only fit a 1 to 5 range; any other range is shown as numbers.
    var resolvedDisplayStyle: DisplayStyle {
        displayStyle == .stars && ratingRange == RatingRange(min: 1, max: 5) ? .stars : .numbers
    }
}
