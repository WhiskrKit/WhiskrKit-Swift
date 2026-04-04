//
//  WhiskrKitAPI.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

public extension View {

	/// Automatically checks eligibility and presents a survey when the modified view appears.
	///
	/// Use this modifier when you want WhiskrKit to decide whether and when to show a survey
	/// based on your configured eligibility rules, such as session count, cooldown periods,
	/// or repeat policies. The survey is evaluated and presented automatically,
	/// without any manual triggering required.
	///
	/// Place this modifier on a view where you want the survey to potentially appear,
	/// such as a home screen, main tab view, or the end of a ticket sales flow.
	/// This ensures that the eligibility check happens at an appropriate time in the user journey,
	/// increasing the likelihood of survey presentation when users are most engaged.
	///
	/// ```swift
	/// SunnyWeatherView()
	///     .whiskrKitSurvey(identifier: "nps-survey")
	/// ```
	///
	/// - Parameter identifier: The identifier of the survey to evaluate and potentially present.
	func whiskrKitSurvey(identifier: String) -> some View {
		self.modifier(
			WhiskrKitSurveyModifier(identifier: identifier)
		)
	}

	/// Registers a view as the attachment point for imperatively triggered surveys.
	///
	/// Use this modifier when you want to trigger surveys manually via
	/// `WhiskrKit.shared.present(surveyId:)`, for example, from a button tap, a push
	/// notification, or any other programmatic trigger. Unlike `whiskrKitSurvey(identifier:)`,
	/// this modifier does not perform any eligibility checks and will not present a survey
	/// on its own. It simply listens for an imperative trigger and handles presentation
	/// when one arrives.
	///
	/// Apply this once, high in your view hierarchy, typically on your root view or
	/// `WindowGroup` content, so it is always active regardless of where the trigger
	/// originates.
	///
	/// ```swift
	/// // In your App.swift
	/// ContentView()
	///     .whiskrKit()
	/// ```
	///
	/// Then trigger a survey from anywhere in your app:
	///
	/// ```swift
	/// // From a button
	/// Button("Give Feedback") {
	///     WhiskrKit.shared.present(surveyId: "nps-survey")
	/// }
	///
	/// // From a push notification handler
	/// if let surveyId = userInfo["whiskrkit_survey_id"] as? String {
	///     WhiskrKit.shared.present(surveyId: surveyId)
	/// }
	/// ```
	///
	/// - Note: If `WhiskrKit.shared.present(surveyId:)` is called but no view with
	///   `.whiskrKit()` is active in the hierarchy, the call is a no-op and no survey
	///   will appear.
	func whiskrKit() -> some View {
		modifier(WhiskrKitSurveyModifier(identifier: nil))
	}
}

struct WhiskrKitSurveyModifier: ViewModifier {
    let identifier: String?

    @State private var template: SurveyTemplate?
    @State private var presentsModal: Bool = false
    @State private var presentsToast: Bool = false
    @State private var presentsFullScreen: Bool = false

    func body(content: Content) -> some View {
        content
            .task {
				guard let identifier else { return }
                await checkEligibilityAndPresent(for: identifier)
            }
            .onChange(of: WhiskrKit.shared.pendingSurveyId) { _, newId in
                guard let newId else { return }
                WhiskrKit.shared.pendingSurveyId = nil
                Task {
                    await fetchSurvey(for: newId)
                }
            }
            .toast(
                isPresented: $presentsToast,
                template: {
                    if case .toast(let template) = template?.presentationBase {
                        template
                    } else {
                        nil
                    }
                }(),
                openFollowUp: { identifier in
                    Task {
                        await fetchSurvey(for: identifier)
                    }
                }
            )
            .sheet(isPresented: $presentsModal) {
                if case .sheet(let template) = template?.presentationBase {
                    sheetContent(template: template)
                        .sheetStyle()
                }
            }
            .fullScreenCover(isPresented: $presentsFullScreen) {
                if case .fullScreenForm(let template) = template?.presentationBase {
                    fullScreenContent(template: template)
                }
            }.environment(
                \.WhiskrKitTheme,
                 WhiskrKit.shared.theme ?? .systemStyle
            )
    }

    @ViewBuilder
    private func sheetContent(template: SheetTemplate) -> some View {
        SheetContainerView(template: template)
            .sheetContentHeight()
    }

    @ViewBuilder
    private func fullScreenContent(template: FullScreenFormTemplate) -> some View {
        FullScreenContainerView(template: template)
    }

    private func checkEligibilityAndPresent(for identifier: String) async {
        let eligibleTemplate: SurveyTemplate? = await WhiskrKit.shared.checkEligibility(for: identifier)
        guard let eligibleTemplate else { return }
        await present(eligibleTemplate)
    }

    private func fetchSurvey(for identifier: String) async {
		let fetchedTemplate: SurveyTemplate? = await WhiskrKit.shared.fetchSurveyTemplate(for: identifier)
		guard let fetchedTemplate else { return }
		await present(fetchedTemplate)
    }

    private func present(_ surveyTemplate: SurveyTemplate) async {
        await MainActor.run {
            self.template = surveyTemplate
            switch surveyTemplate.presentationBase {
            case .fullScreenForm:
                presentsFullScreen = true
            case .sheet:
                presentsModal = true
            case .toast:
                presentsToast = true
            }
        }
    }
}

#Preview {
    Text("Welcome to WhiskrKit")
        .title()
}
