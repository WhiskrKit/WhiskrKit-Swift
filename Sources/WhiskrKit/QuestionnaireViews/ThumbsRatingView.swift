//
//  ThumbsRating.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

enum ThumbsRating: String, CaseIterable, Codable {
    case thumbsUp
    case thumbsDown
    case none
    
    var title: String {
        switch self {
        case .thumbsUp: return String(localized: .ratingButtonThumbsUp)
        case .thumbsDown: return String(localized: .ratingButtonThumbsDown)
        case .none: return ""
        }
    }
    
    var systemImage: String {
        switch self {
        case .thumbsUp: return "hand.thumbsup"
        case .thumbsDown: return "hand.thumbsdown"
        case .none: return ""
        }
    }
    
    var filledSystemImage: String {
        switch self {
        case .thumbsUp: return "hand.thumbsup.fill"
        case .thumbsDown: return "hand.thumbsdown.fill"
        case .none: return ""
        }
    }
    
    var color: Color {
        switch self {
        case .thumbsUp: return .green
        case .thumbsDown: return .red
        case .none: return .gray
        }
    }
}

struct ThumbsRatingView: View {
    @State private var selectedRating: ThumbsRating = .none
    @Environment(SubmissionAlert.self) private var submissionAlert: SubmissionAlert
    
    let template: ThumbsSurveyTemplate
    
    @Binding var surveyResponse: SurveyResponse
    
    var body: some View {
        RatingContainerView(
            title: template.title,
            subtitle: template.subtitle,
            isRequired: template.isRequired
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ForEach([ThumbsRating.thumbsDown, ThumbsRating.thumbsUp], id: \.self) { rating in
                        Button(action: {
                            selectedRating = selectedRating == rating ? .none : rating
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }) {
                            Label(title: {
                                Text(rating.title)
                                    .font(.body)
                                    .fontWeight(selectedRating == rating ? .semibold : .medium)
                                    .foregroundColor(selectedRating == rating ? rating.color : .primary)
                                    .fixedSize()
                            }, icon: {
                                Image(systemName: selectedRating == rating ? rating.filledSystemImage : rating.systemImage)
                                    .font(.title2)
                                    .foregroundColor(selectedRating == rating ? rating.color : .secondary)
                            })
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedRating == rating ? rating.color.opacity(0.15) : Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedRating == rating ? rating.color : Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                        }
                        .accessibilityLabel(rating.title)
                        .accessibilityAddTraits(selectedRating == rating ? [.isSelected] : [])
                        .onChange(of: selectedRating) { _, newValue in
                            if newValue == .none {
                                surveyResponse.results.removeValue(forKey: template.id)
                            } else {
                                surveyResponse.results[template.id] = .thumbsRating(newValue)
                            }
                            withAnimation(.linear.speed(2.0)) {
                                submissionAlert.showAlert[template.id] = newValue == .none
                            }
                        }
                    }
                }
                if submissionAlert.showAlert[template.id] == true {
                    formRequiredMessage
                }
            }
        }
    }
    
    @ViewBuilder
    var formRequiredMessage: some View {
        Label(.formRequiredThumbsRatingMessage, systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .italic()
    }
}

#Preview("Compact Layout") {
    @Previewable @State var submissionAlert = SubmissionAlert()
    ThumbsRatingView(
        template: ThumbsSurveyTemplate(
            id: "1234",
            title: "Rollercoaster",
            subtitle: "Did you enjoy the ride on the rollercoaster?",
            isRequired: false,
            A11yLabel: "",
            A11yHint: ""
        ),
        surveyResponse: .constant(.init(results: [:]))
    )
    .environment(submissionAlert)
}

@available(iOS 26, *)
#Preview {
    @Previewable @State var showing = true
    @Previewable @State var submissionAlert = SubmissionAlert()
    ZStack {
        LinearGradient(gradient: Gradient(colors: [.red, .clear]), startPoint: .top, endPoint: .bottom)
        EmptyView()
            .sheet(isPresented: $showing) {
                ThumbsRatingView(
                    template: ThumbsSurveyTemplate(
                        id: "1234",
                        title: "Rollercoaster",
                        subtitle: "Did you enjoy the ride on the rollercoaster?",
                        isRequired: false,
                        A11yLabel: "",
                        A11yHint: ""
                    ),
                    surveyResponse: .constant(.init(results: [:]))
                )
                .environment(submissionAlert)
                .padding()
                .modifier(ContentHeightSheet())
            }
    }
    .ignoresSafeArea()
}
