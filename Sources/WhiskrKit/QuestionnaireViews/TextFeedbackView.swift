//
//  TextFeedbackView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

// Compact version for inline feedback
struct TextFeedbackView: View {
    @Environment(SubmissionAlert.self) private var submissionAlert: SubmissionAlert
    @State private var feedbackText: String = ""
    @Binding var surveyReponse: SurveyResponse
    
    
    @FocusState private var isTextFieldFocused: Bool
    private var placeholder: String = ""
    
    private var isSubmittable: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var result: String? {
        feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : feedbackText
    }
    
    private var characterLimit: Int {
        template.maxLength ?? 200
    }
    
    private let template: TextSurveyTemplate
    
    init(
        template: TextSurveyTemplate,
        surveyResponse: Binding<SurveyResponse>
    ) {
        self.template = template
        self._surveyReponse = surveyResponse
    }
    
    var body: some View {
        RatingContainerView(
            title: template.title,
            subtitle: template.description,
            isRequired: template.isRequired
        ) {
            VStack(alignment: .leading, spacing: 16) {
                TextField(placeholder, text: $feedbackText, axis: .vertical)
                    .padding()
					.background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .lineLimit(3...6)
                    .accessibilityLabel(.accessibilityTextFieldLabel)
                    .accessibilityHint(.accessibilityTextFieldMaxCharacterLabel(characterLimit))
                    .onChange(of: feedbackText) { _, newValue in
                        if newValue.count > characterLimit {
                            feedbackText = String(newValue.prefix(characterLimit))
                        }
                        submissionAlert.showAlert[template.id] = (template.isRequired && newValue.count == .zero)
                        
                        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            surveyReponse.results.removeValue(forKey: template.id)
                        } else {
                            surveyReponse.results[template.id] = .textualSurvey(newValue)
                        }
                    }
                HStack {
                    if submissionAlert.showAlert[template.id] == true, !isSubmittable {
                        formRequiredMessage
                    }
                    // Character count for compact view
                    if isTextFieldFocused || feedbackText.count > characterLimit * 8/10 {
                        Spacer()
                        Text(verbatim: "\(feedbackText.count)/\(characterLimit)")
                            .font(.caption2)
                            .foregroundColor(feedbackText.count > characterLimit * 9/10 ? .orange : .secondary)
                    }
                }
            }
        }
    }
    
    var formRequiredMessage: some View {
        Label(.formRequiredTextFeedbackMessage, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .italic()
    }
}

#Preview("Compact Feedback") {
    @Previewable @State var submissionAlert = SubmissionAlert()
    
    TextFeedbackView(
        template: .init(
            id: "123",
            title: "Give feedback",
            description: "What do you want to say?",
            isRequired: true,
            A11yLabel: "",
            a11yHint: ""
        ),
        surveyResponse: .constant(.init(results: [:]))
    )
    .environment(submissionAlert)
    .padding()
}

