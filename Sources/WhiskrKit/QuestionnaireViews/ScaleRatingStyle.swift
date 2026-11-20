//
//  ScaleRatingStyle.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

// Pure helpers behind `ScaleRatingView`, kept out of the view so they can be unit
// tested. The Android SDK mirrors them in `ScaleRatingStyle.kt`.

// MARK: - Colors

/// Colors for a selected score button.
///
/// Answer controls are deliberately not themeable, so customers can't pick
/// colors that fail contrast. Every swatch has a relative luminance between 0.18
/// and 0.30: dark text on it stays above 4.5:1, and the fill stays above 3:1
/// against both a white and a black background. The same colors are used in
/// light and dark mode.
enum ScaleRatingPalette {
    enum Swatch: Equatable, CaseIterable {
        case red, gold, green, neutral

        /// 0xRRGGBB, sRGB.
        var hex: UInt32 {
            switch self {
            case .red: 0xE5534B
            case .gold: 0xB8860B
            case .green: 0x2DA44E
            case .neutral: 0x3B82F6
            }
        }

        var color: Color {
            Color(
                .sRGB,
                red: Double((hex >> 16) & 0xFF) / 255,
                green: Double((hex >> 8) & 0xFF) / 255,
                blue: Double(hex & 0xFF) / 255
            )
        }
    }

    /// Text on a selected button. Dark on every swatch, in light and dark mode.
    static let selectedText = Color.black
    /// Width of the outline around a selected button, so selection never relies on color alone.
    static let selectedOutlineWidth: CGFloat = 2

    /// The swatch for a selected score.
    ///
    /// NPS (0 to 10): 0–6 red, 7–8 gold, 9–10 green. CSAT (1 to 5): 4–5 green,
    /// 1–3 neutral. CES and custom: neutral. A preset that arrives with a range
    /// other than its standard one is shown neutral too.
    static func swatch(
        for score: Int,
        metric: ScaleRatingTemplate.Metric,
        range: ScaleRatingTemplate.RatingRange
    ) -> Swatch {
        switch metric {
        case .nps where range == .init(min: 0, max: 10):
            switch score {
            case ...6: .red
            case 7...8: .gold
            default: .green
            }
        case .csat where range == .init(min: 1, max: 5):
            score >= 4 ? .green : .neutral
        default:
            .neutral
        }
    }
}

// MARK: - Layout

enum ScaleRatingLayout {
    /// Most buttons in one row at regular text sizes; 6 keeps 0 to 10 at two rows on an iPhone SE.
    static let maxButtonsPerRow = 6
    static let buttonSpacing: CGFloat = 8
    static let minimumButtonSize: CGFloat = 44

    /// How many buttons fit next to each other in `width`, capped at ``maxButtonsPerRow``.
    /// A `width` of 0 (not measured yet) or an unlimited one allows the maximum.
    static func buttonsPerRow(width: CGFloat, buttonSize: CGFloat, spacing: CGFloat = buttonSpacing) -> Int {
        // An infinite width can't be converted to an Int, so it's handled here first.
        guard width > 0, width.isFinite else { return maxButtonsPerRow }
        let fitting = Int(((width + spacing) / (buttonSize + spacing)).rounded(.down))
        return min(maxButtonsPerRow, max(1, fitting))
    }

    /// The number of buttons in each row, based only on the number of options.
    /// Rows are as even as possible, longer rows first: 11 options in rows of
    /// at most 6 become `[6, 5]`.
    static func rowSizes(optionCount: Int, maxPerRow: Int = maxButtonsPerRow) -> [Int] {
        guard optionCount > 0 else { return [] }
        let perRow = max(1, maxPerRow)
        let rowCount = Int((Double(optionCount) / Double(perRow)).rounded(.up))
        let base = optionCount / rowCount
        let longer = optionCount % rowCount
        return (0..<rowCount).map { $0 < longer ? base + 1 : base }
    }

    /// The scores split into rows, see ``rowSizes(optionCount:maxPerRow:)``.
    static func rows(for range: ClosedRange<Int>, maxPerRow: Int = maxButtonsPerRow) -> [[Int]] {
        var remaining = Array(range)[...]
        return rowSizes(optionCount: remaining.count, maxPerRow: maxPerRow).map { size in
            defer { remaining = remaining.dropFirst(size) }
            return Array(remaining.prefix(size))
        }
    }
}

// MARK: - Labels

enum ScaleRatingLabels {
    /// The labels under the first and last option. The presets use WhiskrKit's own
    /// translated labels; `custom` uses the server's, and shows nothing without them.
    static func endLabels(for template: ScaleRatingTemplate, locale: Locale) -> (min: String?, max: String?) {
        let presets: (min: LocalizedStringResource, max: LocalizedStringResource)?
        switch template.metric {
        case .nps: presets = (.scaleLabelNpsMin, .scaleLabelNpsMax)
        case .csat: presets = (.scaleLabelCsatMin, .scaleLabelCsatMax)
        case .ces: presets = (.scaleLabelCesMin, .scaleLabelCesMax)
        case .custom: presets = nil
        }
        if let presets {
            return (presets.min.resolved(in: locale), presets.max.resolved(in: locale))
        }
        return (nonEmpty(template.minLabel), nonEmpty(template.maxLabel))
    }

    /// What the end labels mean, for VoiceOver: "0 is Not at all likely, 10 is
    /// Extremely likely". `nil` when there are no labels.
    static func endsDescription(for template: ScaleRatingTemplate, locale: Locale) -> String? {
        let labels = endLabels(for: template, locale: locale)
        let parts = [
            labels.min.map { LocalizedStringResource.accessibilityScaleEndLabel(template.ratingRange.min, $0).resolved(in: locale) },
            labels.max.map { LocalizedStringResource.accessibilityScaleEndLabel(template.ratingRange.max, $0).resolved(in: locale) },
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    /// The VoiceOver hint of one score button: "8 out of 10", followed by what the
    /// end labels mean when there are any.
    static func buttonHint(for score: Int, template: ScaleRatingTemplate, locale: Locale) -> String {
        let position = LocalizedStringResource.accessibilityXOutOfYLabel(score, template.ratingRange.max).resolved(in: locale)
        guard let ends = endsDescription(for: template, locale: locale) else { return position }
        return "\(position). \(ends)"
    }

    private static func nonEmpty(_ label: String?) -> String? {
        guard let label = label?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty else { return nil }
        return label
    }
}
