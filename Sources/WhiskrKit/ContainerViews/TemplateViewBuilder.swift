//
//  TemplateViewBuilder.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

final class TemplateViewBuilder {
    static func buildView(for presentation: SurveyPresentation, surveyResponse: Binding<SurveyResponse>) -> some View {
        Group {
            switch presentation.surveyBase {
            case .scaleRating(let base):
                ScaleRatingView(template: base, surveyResponse: surveyResponse)
            case .symbolRating(let base):
                SymbolRatingView(template: base, surveyResponse: surveyResponse)
            case .textualSurvey(let base):
                TextFeedbackView(template: base, surveyResponse: surveyResponse)
            case .thumbsRating(let base):
                ThumbsRatingView(template: base, surveyResponse: surveyResponse)
            }
        }
    }
    
    static func buildSingleContent(
        for presentation: SurveyPresentation,
        surveyResponse: Binding<SurveyResponse>
    ) -> some View {
        buildView(
            for: presentation,
            surveyResponse: surveyResponse
        )
    }
    
    static func buildFullScreenContent(
        withDescription description: String? = nil,
        surveyResponse: Binding<SurveyResponse>,
        for presentations: [SurveyPresentation]
    ) -> some View {
        ForEach(Array(presentations.enumerated()), id: \.offset) { index, presentation in
            buildView(for: presentation, surveyResponse: surveyResponse)
            Divider()
        }
    }
}
