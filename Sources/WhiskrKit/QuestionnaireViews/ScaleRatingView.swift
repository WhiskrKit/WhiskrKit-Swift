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
    @Environment(\.locale) private var locale
    @State private var selectedScore: Int?
    @ScaledMetric(relativeTo: .body) private var scaledButtonSize = ScaleRatingLayout.minimumButtonSize

    let template: ScaleRatingTemplate

    @Binding var surveyResponse: SurveyResponse

    /// - Parameter initialScore: The score shown as selected at first. For previews and
    ///   snapshot tests; surveys always start without a selection.
    init(
        template: ScaleRatingTemplate,
        surveyResponse: Binding<SurveyResponse>,
        initialScore: Int? = nil
    ) {
        self.template = template
        self._surveyResponse = surveyResponse
        self._selectedScore = State(initialValue: initialScore)
    }

    private var buttonSize: CGFloat {
        max(ScaleRatingLayout.minimumButtonSize, scaledButtonSize)
    }

    private var endLabels: (min: String?, max: String?) {
        ScaleRatingLabels.endLabels(for: template, locale: locale)
    }

    var body: some View {
        RatingContainerView(
            title: template.title,
            subtitle: template.subtitle,
            isRequired: template.isRequired
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 8) {
                    switch template.resolvedDisplayStyle {
                    case .numbers: buttonGrid
                    case .stars: stars
                    }
                    endLabelRow
                }
                .onChange(of: selectedScore) { _, newValue in
                    withAnimation(.linear.speed(2.0)) {
                        submissionAlert.showAlert[template.id] = template.isRequired && newValue == nil
                    }
                    surveyResponse.setScaleRating(newValue, for: template.id)
                }
                if submissionAlert.showAlert[template.id] == true, selectedScore == nil {
                    formRequiredMessage
                }
            }
        }
    }

    // MARK: - Numbers

    private var buttonGrid: some View {
        ScaleButtonGrid {
            ForEach(template.ratingRange.asClosedRange, id: \.self) { score in
                scoreButton(for: score)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(ifPresent: template.A11yLabel)
        .accessibilityHint(ifPresent: template.A11yHint)
    }

    @ViewBuilder
    private func scoreButton(for score: Int) -> some View {
        let isSelected = selectedScore == score
        Button(action: {
            withAnimation {
                selectedScore = isSelected ? nil : score
            }
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            Text(verbatim: "\(score)")
                .font(.body.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(isSelected ? ScaleRatingPalette.selectedText : Color.primary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    isSelected
                    ? ScaleRatingPalette.swatch(for: score, metric: template.metric, range: template.ratingRange).color
                    : Color(.systemGray4).opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                // Selection never relies on color alone: an outline, the scale effect and the trait.
                // `Color.primary`, not `.primary`, which a button label tints with the accent color.
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.primary, lineWidth: ScaleRatingPalette.selectedOutlineWidth)
                    }
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: selectedScore)
        }
        .accessibilityLabel(.accessibilityScoreLabel(score))
        .accessibilityValue(
            isSelected
            ? .accessibilityLabelSelected
            : .accessibilityLabelNotSelected
        )
        .accessibilityHint(Text(verbatim: ScaleRatingLabels.buttonHint(for: score, template: template, locale: locale)))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Stars

    private var stars: some View {
        StarRatingControl(
            rating: Binding(
                get: { selectedScore ?? 0 },
                set: { selectedScore = $0 == 0 ? nil : $0 }
            ),
            allowsDeselect: true,
            accessibilityHint: [template.A11yHint, ScaleRatingLabels.endsDescription(for: template, locale: locale)]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: ". ")
        )
        .accessibilityLabel(ifPresent: template.A11yLabel)
    }

    // MARK: - Labels

    /// One line under all rows: the first option's label on the left, the last one's on
    /// the right. When they don't fit on one line (long labels, large text sizes), the
    /// max label moves below the min label, still right-aligned. VoiceOver reads them
    /// as part of each button's hint instead.
    @ViewBuilder
    private var endLabelRow: some View {
        let labels = endLabels
        if labels.min != nil || labels.max != nil {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    if let min = labels.min { Text(verbatim: min).fixedSize() }
                    Spacer(minLength: 0)
                    if let max = labels.max { Text(verbatim: max).fixedSize() }
                }
                VStack(spacing: 4) {
                    if let min = labels.min {
                        Text(verbatim: min)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let max = labels.max {
                        Text(verbatim: max)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
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
}

/// Lays the score buttons out in rows, as many per row as fit in the offered width
/// (at most ``ScaleRatingLayout/maxButtonsPerRow``), with rows as even as possible.
/// Each row spans the full width: the first button at the leading edge, the last at
/// the trailing edge, equal gaps between. Deciding this during layout, rather than
/// from a measured width in state, gets large text sizes right on the first frame.
private struct ScaleButtonGrid: Layout {
    var rowSpacing: CGFloat = 16

    private func rows(width: CGFloat?, subviews: Subviews) -> (rowSizes: [Int], button: CGSize) {
        let button = subviews.first?.sizeThatFits(.unspecified) ?? .zero
        let perRow = ScaleRatingLayout.buttonsPerRow(width: width ?? 0, buttonSize: button.width)
        return (ScaleRatingLayout.rowSizes(optionCount: subviews.count, maxPerRow: perRow), button)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let (rowSizes, button) = rows(width: proposal.width, subviews: subviews)
        let widest = CGFloat(rowSizes.max() ?? 0)
        let naturalWidth = widest * button.width + max(0, widest - 1) * ScaleRatingLayout.buttonSpacing
        let height = CGFloat(rowSizes.count) * button.height + CGFloat(max(0, rowSizes.count - 1)) * rowSpacing
        return CGSize(width: proposal.width ?? naturalWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (rowSizes, button) = rows(width: bounds.width, subviews: subviews)
        var index = 0
        var y = bounds.minY
        for count in rowSizes {
            let gap = count > 1
                ? max(ScaleRatingLayout.buttonSpacing, (bounds.width - CGFloat(count) * button.width) / CGFloat(count - 1))
                : 0
            for column in 0..<count {
                let x = bounds.minX + CGFloat(column) * (button.width + gap)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(button))
                index += 1
            }
            y += button.height + rowSpacing
        }
    }
}

#Preview("NPS", traits: .sizeThatFitsLayout) {
    @Previewable @State var submissionAlert = SubmissionAlert()
    ScaleRatingView(
        template: ScaleRatingTemplate(
            id: "1234",
            title: "How likely are you to recommend Stride to a friend?",
            subtitle: nil,
            ratingRange: .init(min: 0, max: 10),
            isRequired: true,
            A11yLabel: nil,
            A11yHint: nil,
            metric: .nps
        ),
        surveyResponse: .constant(.init(results: [:])),
        initialScore: 8
    )
    .environment(submissionAlert)
}

#Preview("CSAT stars", traits: .sizeThatFitsLayout) {
    @Previewable @State var submissionAlert = SubmissionAlert()
    ScaleRatingView(
        template: ScaleRatingTemplate(
            id: "1234",
            title: "Rate our cookies",
            subtitle: "How satisfied are you with the taste of our chocolate cookies?",
            ratingRange: .init(min: 1, max: 5),
            isRequired: true,
            A11yLabel: nil,
            A11yHint: nil,
            metric: .csat,
            displayStyle: .stars
        ),
        surveyResponse: .constant(.init(results: [:]))
    )
    .environment(submissionAlert)
}
