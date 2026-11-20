//
//  ScaleRatingStyleTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import SwiftUI
import Testing
@testable import WhiskrKit

/// Colors, row layout and end labels of scale ratings (`ScaleRatingStyle.swift`).
@Suite("Scale rating style")
struct ScaleRatingStyleTests {

    // MARK: - Colors

    private let nps = ScaleRatingTemplate.RatingRange(min: 0, max: 10)
    private let csat = ScaleRatingTemplate.RatingRange(min: 1, max: 5)
    private let ces = ScaleRatingTemplate.RatingRange(min: 1, max: 7)

    @Test("NPS: 0 to 6 red, 7 to 8 gold, 9 to 10 green")
    func npsColors() {
        let swatches = (0...10).map { ScaleRatingPalette.swatch(for: $0, metric: .nps, range: nps) }
        #expect(swatches == Array(repeating: .red, count: 7) + [.gold, .gold, .green, .green])
        // The boundaries, spelled out.
        #expect(ScaleRatingPalette.swatch(for: 6, metric: .nps, range: nps) == .red)
        #expect(ScaleRatingPalette.swatch(for: 7, metric: .nps, range: nps) == .gold)
        #expect(ScaleRatingPalette.swatch(for: 8, metric: .nps, range: nps) == .gold)
        #expect(ScaleRatingPalette.swatch(for: 9, metric: .nps, range: nps) == .green)
    }

    @Test("CSAT: 1 to 3 neutral, 4 and 5 green")
    func csatColors() {
        let swatches = (1...5).map { ScaleRatingPalette.swatch(for: $0, metric: .csat, range: csat) }
        #expect(swatches == [.neutral, .neutral, .neutral, .green, .green])
    }

    @Test("CES and custom use one neutral color", arguments: [ScaleRatingTemplate.Metric.ces, .custom])
    func neutralColors(_ metric: ScaleRatingTemplate.Metric) {
        for range in [ces, nps, csat] {
            for score in range.asClosedRange {
                #expect(ScaleRatingPalette.swatch(for: score, metric: metric, range: range) == .neutral)
            }
        }
    }

    @Test("A preset with a non-standard range falls back to neutral")
    func presetWithOtherRange() {
        #expect(ScaleRatingPalette.swatch(for: 10, metric: .nps, range: .init(min: 1, max: 10)) == .neutral)
        #expect(ScaleRatingPalette.swatch(for: 0, metric: .nps, range: .init(min: 0, max: 5)) == .neutral)
        #expect(ScaleRatingPalette.swatch(for: 5, metric: .csat, range: .init(min: 1, max: 7)) == .neutral)
    }

    @Test("Every swatch reaches WCAG contrast with dark text and against light and dark backgrounds")
    func swatchContrast() {
        for swatch in ScaleRatingPalette.Swatch.allCases {
            let fill = relativeLuminance(swatch.hex)
            #expect(contrast(fill, relativeLuminance(0x000000)) >= 4.5, "\(swatch) with black text")
            #expect(contrast(fill, relativeLuminance(0xFFFFFF)) >= 3, "\(swatch) on white")
            #expect(contrast(fill, relativeLuminance(0x000000)) >= 3, "\(swatch) on black")
        }
    }

    private func relativeLuminance(_ hex: UInt32) -> Double {
        func channel(_ value: UInt32) -> Double {
            let c = Double(value & 0xFF) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(hex >> 16) + 0.7152 * channel(hex >> 8) + 0.0722 * channel(hex)
    }

    private func contrast(_ a: Double, _ b: Double) -> Double {
        (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    // MARK: - Layout

    @Test("Rows depend on the number of options, not on the upper bound")
    func rowSizes() {
        #expect(ScaleRatingLayout.rowSizes(optionCount: 5) == [5])
        #expect(ScaleRatingLayout.rowSizes(optionCount: 6) == [6])
        #expect(ScaleRatingLayout.rowSizes(optionCount: 7) == [4, 3])
        #expect(ScaleRatingLayout.rowSizes(optionCount: 11) == [6, 5])
    }

    @Test("Large text wraps to more, evenly filled rows")
    func rowsAtLargeText() {
        #expect(ScaleRatingLayout.rowSizes(optionCount: 11, maxPerRow: 4) == [4, 4, 3])
        #expect(ScaleRatingLayout.rowSizes(optionCount: 11, maxPerRow: 3) == [3, 3, 3, 2])
        #expect(ScaleRatingLayout.rowSizes(optionCount: 5, maxPerRow: 2) == [2, 2, 1])
        #expect(ScaleRatingLayout.rowSizes(optionCount: 0) == [])
    }

    @Test("Buttons per row follow the available width")
    func buttonsPerRow() {
        // iPhone SE content width at the default size: six 44pt buttons fit.
        #expect(ScaleRatingLayout.buttonsPerRow(width: 311, buttonSize: 44) == 6)
        // An accessibility text size makes buttons larger, so fewer fit.
        #expect(ScaleRatingLayout.buttonsPerRow(width: 311, buttonSize: 96) == 3)
        #expect(ScaleRatingLayout.buttonsPerRow(width: 50, buttonSize: 96) == 1)
        // Not measured yet.
        #expect(ScaleRatingLayout.buttonsPerRow(width: 0, buttonSize: 44) == 6)
        // An unlimited width (a horizontal scroll view, `.fixedSize()`) must not trap.
        #expect(ScaleRatingLayout.buttonsPerRow(width: .infinity, buttonSize: 44) == 6)
    }

    // MARK: - Labels

    private func template(
        _ metric: ScaleRatingTemplate.Metric,
        range: ScaleRatingTemplate.RatingRange = .init(min: 0, max: 10),
        minLabel: String? = nil,
        maxLabel: String? = nil
    ) -> ScaleRatingTemplate {
        ScaleRatingTemplate(
            id: "q", title: nil, subtitle: nil, ratingRange: range, isRequired: false,
            A11yLabel: nil, A11yHint: nil, metric: metric, minLabel: minLabel, maxLabel: maxLabel
        )
    }

    private let english = Locale(identifier: "en")

    @Test("Preset metrics use WhiskrKit's English labels")
    func presetLabelsEnglish() {
        #expect(ScaleRatingLabels.endLabels(for: template(.nps), locale: english) == ("Not at all likely", "Extremely likely"))
        #expect(ScaleRatingLabels.endLabels(for: template(.csat), locale: english) == ("Very dissatisfied", "Very satisfied"))
        #expect(ScaleRatingLabels.endLabels(for: template(.ces), locale: english) == ("Very difficult", "Very easy"))
    }

    @Test("Preset labels follow the survey language")
    func presetLabelsTranslated() {
        #expect(ScaleRatingLabels.endLabels(for: template(.csat), locale: Locale(identifier: "nl")) == ("Zeer ontevreden", "Zeer tevreden"))
        #expect(ScaleRatingLabels.endLabels(for: template(.ces), locale: Locale(identifier: "de")) == ("Sehr schwierig", "Sehr einfach"))
    }

    @Test("Preset metrics ignore labels from the server")
    func presetIgnoresServerLabels() {
        let labels = ScaleRatingLabels.endLabels(for: template(.nps, minLabel: "Nope", maxLabel: "Yes!"), locale: english)
        #expect(labels == ("Not at all likely", "Extremely likely"))
    }

    @Test("Custom uses the server's labels")
    func customLabels() {
        let labels = ScaleRatingLabels.endLabels(for: template(.custom, minLabel: "Too easy", maxLabel: "Too hard"), locale: english)
        #expect(labels == ("Too easy", "Too hard"))
    }

    @Test("Custom without labels shows nothing")
    func customWithoutLabels() {
        #expect(ScaleRatingLabels.endLabels(for: template(.custom), locale: english) == (nil, nil))
        #expect(ScaleRatingLabels.endLabels(for: template(.custom, minLabel: "  ", maxLabel: ""), locale: english) == (nil, nil))
        #expect(ScaleRatingLabels.endsDescription(for: template(.custom), locale: english) == nil)
    }

    @Test("VoiceOver hears the position and what the ends mean")
    func accessibilityHint() {
        #expect(
            ScaleRatingLabels.buttonHint(for: 8, template: template(.nps), locale: english)
            == "8 out of 10. 0 is Not at all likely, 10 is Extremely likely"
        )
        #expect(
            ScaleRatingLabels.buttonHint(for: 3, template: template(.custom, range: .init(min: 1, max: 5), maxLabel: "Packed"), locale: english)
            == "3 out of 5. 5 is Packed"
        )
        #expect(ScaleRatingLabels.buttonHint(for: 3, template: template(.custom, range: .init(min: 1, max: 5)), locale: english) == "3 out of 5")
    }

    @Test("A hint built from a resolved ends description matches the one-call form")
    func accessibilityHintWithResolvedEnds() {
        let nps = template(.nps)
        let ends = ScaleRatingLabels.endsDescription(for: nps, locale: english)
        for score in 0...10 {
            #expect(
                ScaleRatingLabels.buttonHint(for: score, template: nps, endsDescription: ends, locale: english)
                == ScaleRatingLabels.buttonHint(for: score, template: nps, locale: english)
            )
        }
    }

    // MARK: - Stars

    @Test("VoiceOver swipes never answer by accident and clear only where tapping does")
    func starAdjustment() {
        // Swiping down on an unanswered row leaves it unanswered.
        #expect(StarRatingControl.adjusted(0, .decrement, allowsDeselect: false) == 0)
        #expect(StarRatingControl.adjusted(0, .decrement, allowsDeselect: true) == 0)
        // Symbol ratings keep one star as the floor; scale stars can be cleared.
        #expect(StarRatingControl.adjusted(1, .decrement, allowsDeselect: false) == 1)
        #expect(StarRatingControl.adjusted(1, .decrement, allowsDeselect: true) == 0)
        #expect(StarRatingControl.adjusted(3, .decrement, allowsDeselect: true) == 2)
        // Swiping up starts at one star and stops at five.
        #expect(StarRatingControl.adjusted(0, .increment, allowsDeselect: true) == 1)
        #expect(StarRatingControl.adjusted(5, .increment, allowsDeselect: false) == 5)
    }
}
