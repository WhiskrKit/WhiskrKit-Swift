//
//  ScaleRatingDecodingTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import Testing
@testable import WhiskrKit

@Suite("Scale rating decoding")
struct ScaleRatingDecodingTests {


    private func decode(_ fields: String) throws -> ScaleRatingTemplate {
        let json = """
        {
          "template": "scaleRating",
          "id": "q_123",
          "title": "How likely are you to recommend Stride to a friend?",
          "subtitle": null,
          "isRequired": true,
          \(fields)
        }
        """
        let presentation = try JSONDecoder().decode(SurveyPresentation.self, from: Data(json.utf8))
        guard case .scaleRating(let template) = presentation.surveyBase else {
            Issue.record("Expected a scale rating")
            throw CancellationError()
        }
        return template
    }

    @Test("A payload from an older server, without the new fields, decodes with defaults")
    func decodesOldPayload() throws {
        let template = try decode(#""ratingRange": { "min": 1, "max": 7 }"#)
        #expect(template.id == "q_123")
        #expect(template.ratingRange == .init(min: 1, max: 7))
        #expect(template.metric == .custom)
        #expect(template.displayStyle == .numbers)
        #expect(template.minLabel == nil)
        #expect(template.maxLabel == nil)
    }

    @Test("A full new payload decodes every field")
    func decodesFullPayload() throws {
        let template = try decode("""
        "ratingRange": { "min": 1, "max": 5 },
        "metric": "csat",
        "displayStyle": "stars",
        "minLabel": "Meh",
        "maxLabel": "Wow",
        "A11yLabel": "Satisfaction",
        "A11yHint": "Pick a score"
        """)
        #expect(template.metric == .csat)
        #expect(template.displayStyle == .stars)
        #expect(template.resolvedDisplayStyle == .stars)
        #expect(template.minLabel == "Meh")
        #expect(template.maxLabel == "Wow")
        #expect(template.A11yLabel == "Satisfaction")
        #expect(template.A11yHint == "Pick a score")
    }

    @Test("The NPS example from the wire contract decodes", arguments: ["nps", "csat", "ces", "custom"])
    func decodesEveryMetric(_ metric: String) throws {
        let template = try decode("""
        "ratingRange": { "min": 0, "max": 10 },
        "metric": "\(metric)",
        "displayStyle": "numbers",
        "minLabel": null,
        "maxLabel": null
        """)
        #expect(template.metric.rawValue == metric)
    }

    @Test("An unknown metric falls back to custom")
    func unknownMetric() throws {
        let template = try decode(#""ratingRange": { "min": 0, "max": 10 }, "metric": "ltr""#)
        #expect(template.metric == .custom)
    }

    @Test("An unknown display style falls back to numbers")
    func unknownDisplayStyle() throws {
        let template = try decode(#""ratingRange": { "min": 1, "max": 5 }, "displayStyle": "emoji""#)
        #expect(template.displayStyle == .numbers)
        #expect(template.resolvedDisplayStyle == .numbers)
    }

    @Test("A wrongly typed new field falls back instead of failing the survey")
    func wronglyTypedFields() throws {
        let template = try decode(#""ratingRange": { "min": 1, "max": 5 }, "metric": 3, "displayStyle": true"#)
        #expect(template.metric == .custom)
        #expect(template.displayStyle == .numbers)
    }

    @Test("Stars with a range other than 1 to 5 render as numbers", arguments: [(0, 5), (1, 7), (0, 10), (2, 5)])
    func starsWithInvalidRange(_ range: (Int, Int)) throws {
        let template = try decode(#""ratingRange": { "min": \#(range.0), "max": \#(range.1) }, "displayStyle": "stars""#)
        #expect(template.displayStyle == .stars)
        #expect(template.resolvedDisplayStyle == .numbers)
    }
}
