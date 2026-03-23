//
//  SheetContainerView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import OSLog

struct SheetContainerView: View {
	@AccessibilityFocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss
    @State private var submissionAlert = SubmissionAlert()

    let template: SheetTemplate

    @State private var surveyResponse: SurveyResponse

    init(template: SheetTemplate) {
        self.template = template
        self.surveyResponse = SurveyResponse(
            results: [:] // Initializes with empty results
        )
    }

    var canSubmit: Bool {
        return surveyResponse.results[template.survey.surveyBase.id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    if let title = template.title {
                        Text(title)
                            .title()
                    }
                    if let description = template.description {
                        Text(description)
                            .subtitle()
                    }
                }
                Spacer()
                closeButton
            }
			.accessibilityFocused($isFocused)
            Divider()
                .padding(.vertical, 8)
            TemplateViewBuilder.buildSingleContent(
                for: template.survey,
                surveyResponse: $surveyResponse
            )
            .environment(submissionAlert)
            if template.followUpQuestion != nil, !surveyResponse.results.isEmpty {
                followUpView
            }
            submitButton
        }
        .padding(.vertical)
        .padding(.horizontal, 24)
		.task {
			try? await Task.sleep(for: .milliseconds(100))
			isFocused = true
		}
    }

    private var submitButton: some View {
        Button {
            submitSurvey()
        } label: {
            Text(.submitButtonLabel)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(WhiskrKitButtonStyle(variant: .primary))
    }

    private var followUpView: some View {
        TextFeedbackView(
            template: TextSurveyTemplate(
                id: "\(template.id)-followUp",
                title: template.followUpQuestion,
                description: nil,
                isRequired: false,
                A11yLabel: nil,
                a11yHint: nil
            ),
            surveyResponse: $surveyResponse
        )
		.environment(submissionAlert)
    }

    @ViewBuilder
    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .circularClose()
        }
        .accessibilityLabel(.accessibilityCloseButtonLabel)
    }

    private func submitSurvey() {
        if canSubmit {
            Logger.wkUI.info("ℹ️ User submitted sheet survey.")
            Task {
                await WhiskrKit.shared.submitSurveyResponse(
                    surveyId: template.id,
                    response: surveyResponse
                )
            }
            dismiss()
        } else {
            withAnimation {
                // Set alert for the required survey that's missing a response
				submissionAlert.showAlert[template.survey.surveyBase.id] = true
            }
        }
    }
}

#Preview("SheetContainerView - stand alone") {
    SheetContainerView(
        template: SheetTemplate(
            id: "1234",
            title: "Quick feedback",
            description: "We'd love to hear from you",
            followUpQuestion: "Tell us more about your experience",
            survey: SurveyPresentation(
                surveyBase: .scaleRating(
                    base:
                        ScaleRatingTemplate(
                            id: "1234",
                            title: "How likely are you to recommend us?",
                            subtitle: "Your feedback helps us improve",
                            ratingRange: .init(min: 1, max: 7),
                            isRequired: true,
                            A11yLabel: "Likelihood to recommend rating",
                            A11yHint: "Rate from 0 to 10"
                        )
                )
            )
        )
    )
    .environment(\.WhiskrKitTheme, .systemStyle)
}

#Preview("SheetContainerView - sheet") {
    @Previewable @State var isPresented: Bool = true
    @Previewable @State var submissionAlert = SubmissionAlert()
    Text("")
        .sheet(isPresented: $isPresented) {
            SheetContainerView(
                template: SheetTemplate(
                    id: "1234",
                    title: "Quick feedback",
                    description: "We'd love to hear from you",
                    followUpQuestion: "What do you need?",
                    survey: SurveyPresentation(
                        surveyBase: .scaleRating(
                            base:
                                ScaleRatingTemplate(
                                    id: "1234",
                                    title: "How likely are you to recommend us?",
                                    subtitle: "Your feedback helps us improve",
                                    ratingRange: .init(min: 1, max: 7),
                                    isRequired: false,
                                    A11yLabel: "Likelihood to recommend rating",
                                    A11yHint: "Rate from 0 to 10"
                                )
                        )
                    )
                )
            )
            .modifier(ContentHeightSheet())
			.environment(\.WhiskrKitTheme, .systemStyle)
            .environment(submissionAlert)
        }
}
