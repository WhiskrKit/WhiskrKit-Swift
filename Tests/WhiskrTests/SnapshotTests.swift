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
/// selection in private `@State`, so mostly default and validation-error states
/// are snapshot here. Error states are injected through `SubmissionAlert`;
/// `ScaleRatingView` takes an `initialScore` so its selected colors can be checked.
@MainActor
@Suite("Snapshot Tests", .snapshots(record: .missing))
struct SnapshotTests {

    // MARK: - Helpers

    /// Goldens are English; pin the locale so a simulator in another language renders the same.
    private static let locale = Locale(identifier: "en")

    private func snap(
        _ view: some View,
        width: CGFloat = 390,
        height: CGFloat,
        dark: Bool = false,
        alert: SubmissionAlert = SubmissionAlert(),
        background: UIColor = .systemBackground,
        theme: WhiskrKitTheme = .systemStyle,
        dynamicType: DynamicTypeSize = .large,
        named name: String? = nil,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let wrapped = view
            .environment(\.WhiskrKitTheme, theme)
            .environment(\.dynamicTypeSize, dynamicType)
            .environment(\.locale, Self.locale)
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

    // MARK: Rating metrics

    /// iPhone SE (2nd and 3rd generation) width, the smallest iOS 17 supports.
    private static let smallScreenWidth: CGFloat = 375

    private func metricTemplate(
        _ metric: ScaleRatingTemplate.Metric,
        range: ScaleRatingTemplate.RatingRange,
        title: String,
        displayStyle: ScaleRatingTemplate.DisplayStyle = .numbers,
        minLabel: String? = nil,
        maxLabel: String? = nil
    ) -> ScaleRatingTemplate {
        ScaleRatingTemplate(
            id: "q1", title: title, subtitle: nil, ratingRange: range, isRequired: true,
            A11yLabel: nil, A11yHint: nil, metric: metric, displayStyle: displayStyle,
            minLabel: minLabel, maxLabel: maxLabel
        )
    }

    private func npsView(score: Int?) -> some View {
        ScaleRatingView(
            template: metricTemplate(.nps, range: .init(min: 0, max: 10), title: "How likely are you to recommend Stride to a friend?"),
            surveyResponse: .constant(.init(results: [:])),
            initialScore: score
        )
    }

    @Test("NPS 0–10 on a small screen")
    func scaleRating_nps() {
        snap(npsView(score: 8), width: Self.smallScreenWidth, height: 340)
    }

    @Test("NPS 0–10 on a small screen — dark")
    func scaleRating_nps_dark() {
        snap(npsView(score: 8), width: Self.smallScreenWidth, height: 340, dark: true)
    }

    @Test("NPS 0–10 on a small screen at an accessibility text size")
    func scaleRating_nps_a11yType() {
        snap(npsView(score: 6), width: Self.smallScreenWidth, height: 1150, dynamicType: .accessibility3)
    }

    @Test("NPS 0–10 on a small screen at an accessibility text size — dark")
    func scaleRating_nps_a11yType_dark() {
        snap(npsView(score: 6), width: Self.smallScreenWidth, height: 1150, dark: true, dynamicType: .accessibility3)
    }

    @Test("NPS 0–10 on a small screen at the largest text size")
    func scaleRating_nps_a11yTypeLargest() {
        snap(npsView(score: 10), width: Self.smallScreenWidth, height: 1900, dynamicType: .accessibility5)
    }

    @Test("CSAT numbers, a satisfied score")
    func scaleRating_csat() {
        snap(
            ScaleRatingView(
                template: metricTemplate(.csat, range: .init(min: 1, max: 5), title: "How satisfied are you with your order?"),
                surveyResponse: .constant(.init(results: [:])),
                initialScore: 4
            ),
            width: Self.smallScreenWidth, height: 220
        )
    }

    @Test("CSAT stars")
    func scaleRating_csatStars() {
        snap(
            ScaleRatingView(
                template: metricTemplate(.csat, range: .init(min: 1, max: 5), title: "How was your delivery?", displayStyle: .stars),
                surveyResponse: .constant(.init(results: [:])),
                initialScore: 4
            ),
            width: Self.smallScreenWidth, height: 200
        )
    }

    @Test("CSAT stars — dark")
    func scaleRating_csatStars_dark() {
        snap(
            ScaleRatingView(
                template: metricTemplate(.csat, range: .init(min: 1, max: 5), title: "How was your delivery?", displayStyle: .stars),
                surveyResponse: .constant(.init(results: [:])),
                initialScore: 4
            ),
            width: Self.smallScreenWidth, height: 200, dark: true
        )
    }

    @Test("CES, neutral selection")
    func scaleRating_ces() {
        snap(
            ScaleRatingView(
                template: metricTemplate(.ces, range: .init(min: 1, max: 7), title: "How easy was it to change your plan?"),
                surveyResponse: .constant(.init(results: [:])),
                initialScore: 6
            ),
            width: Self.smallScreenWidth, height: 300
        )
    }

    @Test("CES, neutral selection — dark")
    func scaleRating_ces_dark() {
        snap(
            ScaleRatingView(
                template: metricTemplate(.ces, range: .init(min: 1, max: 7), title: "How easy was it to change your plan?"),
                surveyResponse: .constant(.init(results: [:])),
                initialScore: 6
            ),
            width: Self.smallScreenWidth, height: 300, dark: true
        )
    }

    @Test("Custom metric with the server's labels")
    func scaleRating_customLabels() {
        snap(
            ScaleRatingView(
                template: metricTemplate(
                    .custom, range: .init(min: 1, max: 10), title: "How did the workout feel?",
                    minLabel: "Way too easy", maxLabel: "Way too hard"
                ),
                surveyResponse: .constant(.init(results: [:])),
                initialScore: 3
            ),
            width: Self.smallScreenWidth, height: 300
        )
    }

    @Test("Stars requested with a range that doesn't fit fall back to numbers")
    func scaleRating_starsInvalidRange() {
        snap(
            ScaleRatingView(
                template: metricTemplate(.custom, range: .init(min: 0, max: 5), title: "Rate the playlist", displayStyle: .stars),
                surveyResponse: .constant(.init(results: [:]))
            ),
            width: Self.smallScreenWidth, height: 200
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
        .environment(\.locale, Self.locale)
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

    /// A toast with a question title, the case where the two titles look alike.
    private var starsToast: ToastTemplate {
        ToastTemplate(
            id: "t1",
            title: "Quick feedback",
            description: "We'd love to hear from you",
            followUpIdentifier: nil,
            survey: SurveyPresentation(
                surveyBase: .symbolRating(
                    base: SymbolRatingTemplate(
                        id: "q1",
                        title: "Rate your experience",
                        description: "Tap the stars to rate",
                        isRequired: true,
                        A11yLabel: nil,
                        A11yHint: nil
                    )
                )
            )
        )
    }

    @Test("Toast — stars question, default text styles")
    func toast_starsQuestion() {
        snap(toastView(starsToast), height: 420, background: .systemGroupedBackground)
    }

    // MARK: - "Powered by WhiskrKit" badge

    private func brandedSheet(_ branding: Bool) -> SheetTemplate {
        var template = sheetTemplate
        template.branding = branding ? Branding(visible: true) : nil
        return template
    }

    private func brandedToast(_ branding: Bool) -> ToastTemplate {
        ToastTemplate(
            id: "t1",
            title: "Planning your trip",
            description: "How satisfied are you with our new planner?",
            followUpIdentifier: nil,
            survey: SurveyPresentation(
                surveyBase: .thumbsRating(
                    base: ThumbsSurveyTemplate(
                        id: "q1", title: nil, subtitle: nil, isRequired: false, A11yLabel: nil, A11yHint: nil
                    )
                )
            ),
            branding: branding ? Branding(visible: true) : nil
        )
    }

    /// Low-contrast secondary text on a dark custom surface: the badge must fall back to white.
    private var lowContrastTheme: WhiskrKitTheme {
        var theme = WhiskrKitTheme.systemStyle
        let navy = Color(red: 0.106, green: 0.106, blue: 0.184)
        theme.container = .init(
            sheet: .init(backgroundColor: navy),
            toast: .init(cornerRadius: 8, backgroundColor: navy, withShadow: false)
        )
        theme.title.color = Color(red: 0.95, green: 0.95, blue: 0.97)
        theme.headline.color = Color(red: 0.95, green: 0.95, blue: 0.97)
        theme.body.color = Color(red: 0.95, green: 0.95, blue: 0.97)
        theme.subtitle.color = Color(red: 0.65, green: 0.65, blue: 0.75)
        theme.subheadline.color = Color(red: 0.25, green: 0.25, blue: 0.42)
        theme.button.primary = .variant(.init(
            backgroundColor: Color(red: 0.96, green: 0.77, blue: 0.26),
            textColor: Color(red: 0.106, green: 0.106, blue: 0.184),
            font: .body.weight(.medium),
            cornerRadius: 10
        ))
        return theme
    }

    private static let navy = UIColor(red: 0.106, green: 0.106, blue: 0.184, alpha: 1)

    @Test("Toast — with branding")
    func toast_branding() {
        snap(toastView(brandedToast(true)), height: 420, background: .systemGroupedBackground)
    }

    @Test("Toast — without branding")
    func toast_noBranding() {
        snap(toastView(brandedToast(false)), height: 420, background: .systemGroupedBackground)
    }

    @Test("Toast — with branding, dark")
    func toast_branding_dark() {
        snap(toastView(brandedToast(true)), height: 420, dark: true, background: .systemGroupedBackground)
    }

    @Test("Toast — with branding, accessibility Dynamic Type")
    func toast_branding_a11yType() {
        snap(
            toastView(brandedToast(true)),
            height: 1500,
            background: .systemGroupedBackground,
            dynamicType: .accessibility3
        )
    }

    @Test("Toast — with branding, custom low-contrast theme")
    func toast_branding_themed() {
        snap(toastView(brandedToast(true)), height: 420, dark: true, background: Self.navy, theme: lowContrastTheme)
    }

    @Test("Sheet — with branding")
    func sheet_branding() {
        snap(SheetContainerView(template: brandedSheet(true)), height: 520)
    }

    @Test("Sheet — without branding")
    func sheet_noBranding() {
        snap(SheetContainerView(template: brandedSheet(false)), height: 520)
    }

    @Test("Sheet — with branding, dark")
    func sheet_branding_dark() {
        snap(SheetContainerView(template: brandedSheet(true)), height: 520, dark: true)
    }

    @Test("Sheet — with branding, accessibility Dynamic Type")
    func sheet_branding_a11yType() {
        snap(
            SheetContainerView(template: brandedSheet(true)),
            height: 1100,
            dynamicType: .accessibility3
        )
    }

    @Test("Sheet — with branding, largest accessibility Dynamic Type")
    func sheet_branding_a11yTypeLargest() {
        snap(
            SheetContainerView(template: brandedSheet(true)),
            height: 1300,
            dynamicType: .accessibility5
        )
    }

    @Test("Sheet — with branding, custom low-contrast theme")
    func sheet_branding_themed() {
        snap(SheetContainerView(template: brandedSheet(true)), height: 520, dark: true, background: Self.navy, theme: lowContrastTheme)
    }
}
