//
//  ScaleRatingView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct ScaleRatingView: View {
    @Environment(SubmissionAlert.self) private var submissionAlert: SubmissionAlert
    @Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
    @State private var selectedScore: Int? = nil
    
    private var (firstRow, secondRow): ([Int], [Int])
    
    let template: ScaleRatingTemplate
    
    @Binding var surveyResponse: SurveyResponse
    
    init(
        template: ScaleRatingTemplate,
        surveyResponse: Binding<SurveyResponse>
    ) {
        self.template = template
        self._surveyResponse = surveyResponse
        (firstRow, secondRow) = ScaleRatingView.splitRange(template.ratingRange.asClosedRange)
    }
    
    var body: some View {
        RatingContainerView(
            title: template.title,
            subtitle: template.subtitle,
            isRequired: template.isRequired
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Rating buttons in two rows for better mobile layout
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(firstRow, id: \.self) { score in
                            scoreButton(for: score)
                            if score != firstRow.last { Spacer() }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(secondRow, id: \.self) { score in
                            scoreButton(for: score)
                            if score != secondRow.last { Spacer() }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(template.A11yLabel ?? "")
                .accessibilityHint(template.A11yHint ?? "")
                .onChange(of: selectedScore) { _, newValue in
                    withAnimation(.linear.speed(2.0)) {
                        submissionAlert.showAlert[template.id] = newValue == nil
                    }
                    guard let newValue else { return }
                    surveyResponse.results[template.id] = .npsRating(newValue)
                }
                if submissionAlert.showAlert[template.id] == true, selectedScore == nil {
                    formRequiredMessage
                }
            }
        }
    }
    
    @ViewBuilder
    private func scoreButton(for score: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedScore = selectedScore == score ? nil : score
            }
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Text(verbatim: "\(score)")
                .font(.body.bold())
                .scaleEffect(selectedScore == score ? 1.1 : 1.0)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(
                    selectedScore == score ?
                    color(for: score) :
                        Color(.systemGray4).opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .animation(.easeInOut(duration: 0.15), value: selectedScore)
        }
        .accessibilityLabel(.accessibilityScoreLabel(score))
        .accessibilityValue(
            selectedScore == score
            ? .accessibilityLabelSelected
            : .accessibilityLabelNotSelected
        )
        .accessibilityHint(.accessibilityXOutOfYLabel(score, template.ratingRange.max))
        .accessibilityAddTraits(selectedScore == score ? [.isSelected] : [])
    }
    
    @ViewBuilder
    var formRequiredMessage: some View {
        Label(
            .formRequiredScaleRatingMessage(
                template.ratingRange.min,
                template.ratingRange.max
            ),
            systemImage: "exclamationmark.circle.fill"
        )
        .font(.footnote)
        .foregroundStyle(.red)
        .italic()
    }
    
    private func color(for number: Int) -> Color {
        let progress = Double(number - template.ratingRange.min) /
        Double(template.ratingRange.max - template.ratingRange.min)
        
        return interpolatedColor(progress: progress)
    }
    
    private func interpolatedColor(progress: Double) -> Color {
        if progress < 0.5 {
            // red -> yellow
            let t = progress / 0.5
            return Color(red: 1.0, green: t, blue: 0.0)
        } else {
            // yellow -> green
            let t = (progress - 0.5) / 0.5
            return Color(red: 1.0 - t, green: 1.0, blue: 0.0)
        }
    }
    
    private static func splitRange(_ range: ClosedRange<Int>) -> ([Int], [Int]) {
        guard range.upperBound > 5 else { return (Array(range), []) }
        let allValues = Array(range)
        let half = Int(ceil(Double(allValues.count) / 2.0))
        let firstRow = Array(allValues.prefix(half))
        let secondRow = Array(allValues.suffix(allValues.count - half))
        return (firstRow, secondRow)
    }
}

#Preview("Button Grid", traits: .sizeThatFitsLayout) {
    @Previewable @State var submissionAlert = SubmissionAlert()
    ScaleRatingView(
        template: ScaleRatingTemplate(
            id: "1234",
            title: "Rate our cookies",
            subtitle: "How satisfied are you with the taste of our chocolate cookies?",
            ratingRange: .init(min: 1, max: 5),
            isRequired: true,
            A11yLabel: "",
            A11yHint: ""
        ),
        surveyResponse: .constant(.init(results: [:]))
    )
    .environment(submissionAlert)
}
