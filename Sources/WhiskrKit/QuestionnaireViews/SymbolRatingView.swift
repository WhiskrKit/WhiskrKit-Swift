//
//  SymbolRating.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct SymbolRatingView: View {
    @Environment(SubmissionAlert.self) private var submissionAlert: SubmissionAlert
    @State private var rating: Int = 0
    
    let template: SymbolRatingTemplate
    @Binding var surveyResponse: SurveyResponse
    
    var body: some View {
        RatingContainerView(
            title: template.title,
            subtitle: template.description,
            isRequired: template.isRequired
        ) {
            VStack(alignment: .leading, spacing: 16) {
                StarRatingControl(rating: $rating)
                    .onChange(of: rating) { _, newValue in
                        surveyResponse.results[template.id] = .symbolRating(newValue)
                    }
                if submissionAlert.showAlert[template.id] == true, rating == 0 {
                    formRequiredMessage
                }
            }
        }
    }
    
    @ViewBuilder
    var formRequiredMessage: some View {
        Label(.formRequiredSymbolRatingMessage(1, stars: 5), systemImage: "exclamationmark.circle.fill")
            .font(.footnote)
            .foregroundStyle(.red)
            .italic()
    }
}

/// Five tappable stars, used by symbol rating questions and by scale ratings shown
/// as stars. `rating` is 0 while nothing is chosen. VoiceOver reads the row as one
/// adjustable element: swipe up or down to change the rating.
struct StarRatingControl: View {
    nonisolated static let starCount = 5

    @Binding var rating: Int
    /// Tapping the chosen star again clears the rating.
    var allowsDeselect = false
    var accessibilityHint: String? = nil

    var body: some View {
        HStack {
            ForEach(1...Self.starCount, id: \.self) { star in
                Button(action: {
                    withAnimation {
                        rating = allowsDeselect && rating == star ? 0 : star
                    }
                    // Haptic feedback for better UX
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundColor(star <= rating ? .yellow : .gray)
                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: rating)
                }
                if star < Self.starCount {
                    Spacer()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(.accessibilitySymbolRatingLabel)
        .accessibilityValue(
            rating == 0
            ? .accessibilityLabelNotSelected
            : .accessibilityXOutOfYSymbolLabel(rating, stars: Self.starCount)
        )
        .accessibilityHint(ifPresent: accessibilityHint)
        .accessibilityAdjustableAction { direction in
            rating = Self.adjusted(rating, direction, allowsDeselect: allowsDeselect)
        }
    }

    /// The rating after a VoiceOver swipe up or down. Swiping down while nothing is
    /// chosen leaves it unanswered. With `allowsDeselect`, swiping down from one star
    /// clears the rating, as tapping the chosen star does; otherwise one star is the floor.
    nonisolated static func adjusted(
        _ rating: Int,
        _ direction: AccessibilityAdjustmentDirection,
        allowsDeselect: Bool
    ) -> Int {
        switch direction {
        case .increment:
            return min(rating + 1, starCount)
        case .decrement:
            guard rating > 0 else { return 0 }
            return max(rating - 1, allowsDeselect ? 0 : 1)
        @unknown default:
            return rating
        }
    }
}

#Preview {
    @Previewable @State var submissionAlert = SubmissionAlert()
    
    SymbolRatingView(
        template: SymbolRatingTemplate(
            id: "1234",
            title: "Ticket purchase",
            description: "How well did buying your ticket go?",
            isRequired: true,
            A11yLabel: "",
            A11yHint: ""
        ),
        surveyResponse: .constant(.init(results: [:]))
    )
    .environment(submissionAlert)
}
