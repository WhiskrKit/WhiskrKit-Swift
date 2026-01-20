//
//  FullScreenContainerView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import OSLog

struct FullScreenContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    @State private var submissionAlert = SubmissionAlert()
    
    let template: FullScreenFormTemplate
    
    @State private var surveyResponse: SurveyResponse
    
    init(template: FullScreenFormTemplate) {
        self.template = template
        self.surveyResponse = SurveyResponse(
            results: [:]
        )
    }
    
    /// Returns the surveys that are required but missing a response
    private var missingSurveys: [SurveyPresentation] {
        template.surveys.filter { survey in
            survey.surveyBase.isRequired && surveyResponse.results[survey.surveyBase.id] == nil
        }
    }
    
    private var canSubmit: Bool {
        missingSurveys.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let description = template.description {
                        Divider()
                        Text(description)
                            .body()
                            .italic()
                        Divider()
                    }
                    TemplateViewBuilder
                        .buildFullScreenContent(
                            withDescription: template.description,
                            surveyResponse: $surveyResponse,
                            for: template.surveys
                        )
                        .environment(submissionAlert)
                    /* Creating a custom ViewModifier for the background in a
                     NavigationStack causes unwanted scroll insets with the navigationTitle.
                     */
                    Spacer()
                    submitButton
                }
            }
            .padding(.horizontal)
            .background(
                WhiskrKitTheme.container?.fullScreen?.backgroundColor.ignoresSafeArea()
            )
            .navigationTitle(template.title ?? "Survey") // localize survey
            .navigationSubtitleIfAvailable(template.subtitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    closeButton
                }
            }
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
    
    private var closeButton: some View {
        Button(.closeButtonLabel, systemImage: "xmark") {
            dismiss()
        }
    }
    
    private func submitSurvey() {
        if canSubmit {
            Logger.wkUI.info("ℹ️ User submitted fullscreen survey.")
            Task {
                await WhiskrKit.shared.submitSurveyResponse(
                    surveyId: template.id,
                    response: surveyResponse
                )
            }
            dismiss()
        } else {
            withAnimation {
                for survey in missingSurveys {
                    submissionAlert.showAlert[survey.surveyBase.id] = true
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func navigationSubtitleIfAvailable(_ subtitle: String?) -> some View {
        if #available(iOS 26, *), let subtitle {
            self.navigationSubtitle(subtitle)
        } else {
            self
        }
    }
}

#Preview("FullScreenContainerView - Main") {
    @Previewable @State var submissionAlert = SubmissionAlert()
    FullScreenContainerView(
        template: .init(
            id: "2345",
            title: "Ticket purchase",
            subtitle: "How did buying your ticket go?",
            description: "Thank you for taking some time to help us improve our product. Your answers will help us make your future purchases better.",
            surveys: [
                SurveyPresentation(
                    surveyBase: .scaleRating(
                        base:
                            ScaleRatingTemplate(
                                id: "1234",
                                title: "How likely are you to recommend us?",
                                subtitle: "Your feedback helps us improve",
                                ratingRange: .init(
                                    min: 1,
                                    max: 7
                                ),
                                isRequired: true,
                                A11yLabel: "Likelihood to recommend rating",
                                A11yHint: "Rate from 0 to 10"
                            )
                    )
                ),
                SurveyPresentation(
                    surveyBase: .textualSurvey(
                        base: TextSurveyTemplate(
                            id: "123",
                            title: "What went well?",
                            description: "Can you tell us what went well?",
                            isRequired: false, A11yLabel: "",
                            a11yHint: ""
                        )
                    )
                ),
                SurveyPresentation(
                    surveyBase: .textualSurvey(
                        base: TextSurveyTemplate(
                            id: "123",
                            title: "What can we improve?",
                            description: "Can you tell us where we can improve?",
                            isRequired: false,
                            A11yLabel: "",
                            a11yHint: ""
                        )
                    )
                ),
                SurveyPresentation(
                    surveyBase: .textualSurvey(
                        base: TextSurveyTemplate(
                            id: "833",
                            title: "Anything else?",
                            description: "Is there anything else you would like to tell us?",
                            isRequired: true,
                            A11yLabel: "",
                            a11yHint: ""
                        )
                    )
                )
            ]
        )
    )
    .environment(\.WhiskrKitTheme, .systemStyle)
    .environment(submissionAlert)
}
