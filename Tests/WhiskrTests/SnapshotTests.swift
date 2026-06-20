//
//  SnapshotTests.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SnapshotTesting
import SwiftUI
import Testing
@testable import WhiskrKit

/// Golden-image tests mirroring the Android SDK's Roborazzi suite
/// (whiskrkit-android, `SnapshotTest.kt`) scenario-for-scenario, so the two
/// SDKs can be reviewed side by side.
///
/// Workflow: a first run records any missing reference images into
/// `__Snapshots__` (and fails); the second run verifies against them. Goldens
/// are committed. Re-record deliberately after Xcode/simulator upgrades.
///
/// Note: unlike the Android views (hoisted state), the iOS question views keep
/// selection in private `@State`, so only default and validation-error states
/// can be snapshot here. Error states are injected through `SubmissionAlert`.
@MainActor
@Suite("Snapshot Tests", .snapshots(record: .missing))
struct SnapshotTests {

    // MARK: - Helpers

    private func snap(
        _ view: some View,
        width: CGFloat = 390,
        height: CGFloat,
        dark: Bool = false,
        alert: SubmissionAlert = SubmissionAlert(),
        background: UIColor = .systemBackground,
        named name: String? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let wrapped = view
            .environment(\.WhiskrKitTheme, .systemStyle)
            .environment(alert)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(background))
            .environment(\.colorScheme, dark ? .dark : .light)

        assertSnapshot(
            of: wrapped,
            as: .image(
                layout: .fixed(width: width, height: height),
                traits: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
            ),
            named: name,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }

    private func requiredAlert(for questionId: String) -> SubmissionAlert {
        let alert = SubmissionAlert()
        alert.showAlert[questionId] = true
        return alert
    }

    // MARK: - Question views

    @Test("Scale rating — default state")
    func scaleRating() {
        snap(
            ScaleRatingView(
                template: ScaleRatingTemplate(
                    id: "q1",
                    title: "How likely are you to recommend us?",
                    subtitle: "Your feedback helps us improve",
                    ratingRange: .init(min: 0, max: 10),
                    isRequired: true,
                    A11yLabel: nil,
                    A11yHint: nil
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 320
        )
    }

    @Test("Scale rating — validation error")
    func scaleRating_error() {
        snap(
            ScaleRatingView(
                template: ScaleRatingTemplate(
                    id: "q1",
                    title: "Rate our cookies",
                    subtitle: nil,
                    ratingRange: .init(min: 1, max: 5),
                    isRequired: true,
                    A11yLabel: nil,
                    A11yHint: nil
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 240,
            alert: requiredAlert(for: "q1")
        )
    }

    @Test("Symbol rating")
    func symbolRating() {
        snap(
            SymbolRatingView(
                template: SymbolRatingTemplate(
                    id: "q1",
                    title: "Ticket purchase",
                    description: "How well did buying your ticket go?",
                    opensStoreReview: false,
                    isRequired: false,
                    A11yLabel: nil,
                    A11yHint: nil
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 220
        )
    }

    @Test("Thumbs rating")
    func thumbsRating() {
        snap(
            ThumbsRatingView(
                template: ThumbsSurveyTemplate(
                    id: "q1",
                    title: "Rollercoaster",
                    subtitle: "Did you enjoy the ride?",
                    isRequired: false,
                    A11yLabel: nil,
                    A11yHint: nil
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 240
        )
    }

    @Test("Text feedback")
    func textFeedback() {
        snap(
            TextFeedbackView(
                template: TextSurveyTemplate(
                    id: "q1",
                    title: "Give feedback",
                    description: "What do you want to say?",
                    isRequired: true,
                    A11yLabel: nil,
                    a11yHint: nil
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 300
        )
    }

    @Test("Multiple choice — single select")
    func multipleChoice_single() {
        snap(
            MultipleChoiceQuestionView(
                template: MultipleChoiceTemplate(
                    id: "q1",
                    title: "How long have you been using the app?",
                    subtitle: nil,
                    isRequired: true,
                    options: [
                        MultipleChoiceOption(id: "1", label: "Less than a year"),
                        MultipleChoiceOption(id: "2", label: "1–3 years"),
                        MultipleChoiceOption(id: "3", label: "3+ years"),
                    ],
                    allowsMultiSelection: false
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 360
        )
    }

    @Test("Multiple choice — multi select")
    func multipleChoice_multi() {
        snap(
            MultipleChoiceQuestionView(
                template: MultipleChoiceTemplate(
                    id: "q1",
                    title: "Which features do you use?",
                    subtitle: "Select all that apply",
                    isRequired: false,
                    options: [
                        MultipleChoiceOption(id: "1", label: "Surveys"),
                        MultipleChoiceOption(id: "2", label: "Analytics"),
                        MultipleChoiceOption(id: "3", label: "Feedback forms"),
                    ],
                    allowsMultiSelection: true
                ),
                surveyResponse: .constant(.init(results: [:]))
            ),
            height: 380
        )
    }

    // MARK: - Containers

    private var sheetTemplate: SheetTemplate {
        SheetTemplate(
            id: "s1",
            title: "Quick feedback",
            description: "We'd love to hear from you",
            followUpQuestion: "Tell us more about your experience",
            survey: SurveyPresentation(
                surveyBase: .scaleRating(
                    base: ScaleRatingTemplate(
                        id: "q1",
                        title: "How likely are you to recommend us?",
                        subtitle: nil,
                        ratingRange: .init(min: 1, max: 7),
                        isRequired: true,
                        A11yLabel: nil,
                        A11yHint: nil
                    )
                )
            )
        )
    }

    @Test("Sheet container")
    func sheetContent() {
        snap(SheetContainerView(template: sheetTemplate), height: 480)
    }

    @Test("Sheet container — dark")
    func sheetContent_dark() {
        snap(
            SheetContainerView(
                template: SheetTemplate(
                    id: "s1",
                    title: "Quick feedback",
                    description: "We'd love to hear from you",
                    followUpQuestion: nil,
                    survey: SurveyPresentation(
                        surveyBase: .thumbsRating(
                            base: ThumbsSurveyTemplate(
                                id: "q1",
                                title: nil,
                                subtitle: nil,
                                isRequired: false,
                                A11yLabel: nil,
                                A11yHint: nil
                            )
                        )
                    )
                )
            ),
            height: 360,
            dark: true
        )
    }

    /// Renders the iPad floating panel with a fixed content height. The card
    /// otherwise sizes itself from an async content measurement that never settles
    /// inside a snapshot (the same reason the sheet snapshots above use
    /// `SheetContainerView` directly), so a deterministic height is injected.
    private func snapPanel(
        _ placement: SheetPlacement,
        sizeClass: UIUserInterfaceSizeClass = .regular,
        width: CGFloat,
        height: CGFloat,
        contentHeight: CGFloat = 380,
        named name: String? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let panel = FloatingPanelView(
            template: sheetTemplate,
            placement: placement,
            onDismiss: {},
            previewContentHeight: contentHeight
        )
        .environment(\.WhiskrKitTheme, .systemStyle)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))

        let traits = UITraitCollection { mutable in
            mutable.userInterfaceStyle = .light
            mutable.horizontalSizeClass = sizeClass
        }

        assertSnapshot(
            of: panel,
            as: .image(layout: .fixed(width: width, height: height), traits: traits),
            named: name,
            fileID: fileID,
            file: filePath,
            testName: testName,
            line: line,
            column: column
        )
    }

    @Test("Floating panel — leading side card (regular width)")
    func panel_leading() {
        snapPanel(.leading, width: 768, height: 600)
    }

    @Test("Floating panel — trailing side card (regular width)")
    func panel_trailing() {
        snapPanel(.trailing, width: 768, height: 600)
    }

    @Test("Floating panel — bottom centered (regular width)")
    func panel_bottomCentered() {
        snapPanel(.bottomCentered, width: 768, height: 600)
    }

    @Test("Floating panel — compact falls back to full-width bottom card")
    func panel_compactFallback() {
        snapPanel(.leading, sizeClass: .compact, width: 390, height: 600)
    }

    @Test("Full screen form")
    func fullScreenContent() {
        snap(
            FullScreenContainerView(
                template: FullScreenFormTemplate(
                    id: "f1",
                    title: "Ticket purchase",
                    subtitle: "How did buying your ticket go?",
                    description: "Thank you for taking some time to help us improve.",
                    surveys: [
                        SurveyPresentation(
                            surveyBase: .scaleRating(
                                base: ScaleRatingTemplate(
                                    id: "q1",
                                    title: "How likely are you to recommend us?",
                                    subtitle: nil,
                                    ratingRange: .init(min: 1, max: 7),
                                    isRequired: true,
                                    A11yLabel: nil,
                                    A11yHint: nil
                                )
                            )
                        ),
                        SurveyPresentation(
                            surveyBase: .textualSurvey(
                                base: TextSurveyTemplate(
                                    id: "q2",
                                    title: "What went well?",
                                    description: nil,
                                    isRequired: false,
                                    A11yLabel: nil,
                                    a11yHint: nil
                                )
                            )
                        ),
                    ]
                )
            ),
            height: 844
        )
    }

    // MARK: - Toast (Android: "banner")

    /// ToastView animates in from `offSetY = 50`; snapshots capture the initial
    /// offset, so toast scenarios get extra bottom room to avoid clipping.

    private func toastView(_ template: ToastTemplate) -> some View {
        ToastView(
            isVisible: .constant(true),
            template: template,
            openFollowUp: { _ in }
        )
        .padding(.bottom, 60)
    }

    @Test("Toast — inline question")
    func toast_inlineQuestion() {
        snap(
            toastView(
                ToastTemplate(
                    id: "t1",
                    title: "Planning your trip",
                    description: "How satisfied are you with our new planner?",
                    followUpIdentifier: nil,
                    survey: SurveyPresentation(
                        surveyBase: .thumbsRating(
                            base: ThumbsSurveyTemplate(
                                id: "q1",
                                title: nil,
                                subtitle: nil,
                                isRequired: false,
                                A11yLabel: nil,
                                A11yHint: nil
                            )
                        )
                    )
                )
            ),
            height: 420,
            background: .systemGroupedBackground
        )
    }

    @Test("Toast — follow-up buttons")
    func toast_followUpButtons() {
        snap(
            toastView(
                ToastTemplate(
                    id: "t1",
                    title: "Got a minute?",
                    description: "We'd love to hear how onboarding went.",
                    followUpIdentifier: "next",
                    survey: nil
                )
            ),
            height: 300,
            background: .systemGroupedBackground
        )
    }

    @Test("Toast — dark")
    func toast_dark() {
        snap(
            toastView(
                ToastTemplate(
                    id: "t1",
                    title: "Got a minute?",
                    description: "We'd love to hear how onboarding went.",
                    followUpIdentifier: "next",
                    survey: nil
                )
            ),
            height: 300,
            dark: true,
            background: .systemGroupedBackground
        )
    }
}
