//
//  WhiskrKit.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import Observation
import OSLog

@MainActor
@Observable
public class WhiskrKit {
    public static let shared = WhiskrKit()

    private var apiKey: String?
    var theme: WhiskrKitTheme?
    private var configurationService: ConfigurationService

    private var eligibilityStorage: any EligibilityStorage = UserDefaultsEligibilityStorage()
    private var eligibilityService: EligibilityService?

	var pendingSurveyId: String? = nil

    private init() {
		configurationService = WhiskrKitConfigurationService()
    }


	/// Initializes WhiskrKit with the provided API key and configuration options.
	///
	/// This method must be called before using any other WhiskrKit features. It configures
	/// the SDK with your API credentials and sets up the configuration service. The option for mocked data will be removed when the SDK has production state.
	///
	/// - Parameters:
	///   - apiKey: Your WhiskrKit API key used for authentication and survey management. When using the mocked option, use a random String.
	///   - withMockedSurveys: A boolean indicating whether to use mocked survey data for testing purposes. Its default is set to false.
	public func initialize(apiKey: String, withMockedSurveys mockedSurveys: Bool = false) {
        self.apiKey = apiKey
		configurationService.configure(apiKey: apiKey)

		if mockedSurveys {
			let mockService = MockConfigurationService()
			configurationService = mockService
			eligibilityService = MockEligibilityService(configurationService: mockService)
		} else {
			// Eligibility context tracking
			eligibilityStorage.initializeIfNeeded()
			eligibilityStorage.incrementSessionCount()
			eligibilityService = WhiskrKitEligibilityService(
				networkService: configurationService.networkService,
				storage: eligibilityStorage
			)
		}
    }


	/// Configures the visual appearance of WhiskrKit surveys throughout your app.
	///
	/// Use this method to customize the look and feel of survey components by providing
	/// a `WhiskrKitTheme` instance. The theme controls colors, fonts, spacing, and other
	/// visual properties of survey UI elements.
	///
	/// To create a theme, initialize a `WhiskrKitTheme` with your desired styling:
	///
	/// ```swift
	/// let customTheme = WhiskrKitTheme(
	///     primaryColor: .blue,
	///     backgroundColor: .white,
	///     textColor: .black
	/// )
	/// WhiskrKit.shared.setTheme(customTheme)
	/// ```
	///
	///	Inside the `WhiskrKitTheme.swift` file you can find an extension with an example theme. You can also use this theme yourself as follows:
	///
	///	```swift
	///	WhiskrKit.shared.setTheme(.systemStyle)
	///	```
	///
	/// - Parameter theme: A `WhiskrKitTheme` instance defining the visual styling for surveys.
	///
	/// - Note: Call this method after `initialize(apiKey:withMockedSurveys:)` to ensure
	///   the theme is applied to all survey presentations. The theme persists for the lifetime
	///   of the app session.
	///
	public func setTheme(_ theme: WhiskrKitTheme) {
		self.theme = theme
	}

	/// Imperatively presents a survey with the given identifier, bypassing eligibility checks.
	///
	/// Use this method to trigger a survey programmatically, for example, from a button tap,
	/// a remote push notification, or any other non-automatic trigger. Unlike the
	/// `whiskrKitSurvey(identifier:)` view modifier, this method does not evaluate eligibility
	/// rules before presenting.
	///
	/// - Parameter surveyId: The identifier of the survey to present.
	///
	/// - Note: At least one view in your app's hierarchy must have `whiskrKit()` or the `whiskrKitSurvey(identifier:)`
	///   modifier attached for the survey to appear. If no modifier is active, the call is a no-op.
	///
	/// - Important: This method must be called after `initialize(apiKey:withMockedSurveys:)`.
	///
	/// ## Example: Presenting from a button
	/// ```swift
	/// Button("Give Feedback") {
	///     WhiskrKit.shared.present(surveyId: "nps-survey")
	/// }
	/// ```
	///
	/// ## Example: Presenting from a push notification
	/// ```swift
	/// func userNotificationCenter(
	///     _ center: UNUserNotificationCenter,
	///     didReceive response: UNNotificationResponse,
	///     withCompletionHandler completionHandler: @escaping () -> Void
	/// ) {
	///     if let surveyId = response.notification.request.content.userInfo["whiskrkit_survey_id"] as? String {
	///         WhiskrKit.shared.present(surveyId: surveyId)
	///     }
	///     completionHandler()
	/// }
	/// ```
	public func present(surveyId: String) {
		 pendingSurveyId = surveyId
	 }

	/// Checks eligibility for a survey and presents it if the user qualifies.
	///
	/// Use this when you want backend-controlled targeting but need to trigger
	/// the check at a specific moment, for example, when a sheet is dismissed
	/// or after a user completes a flow.
	///
	/// Unlike `present(surveyId:)`, this method respects eligibility rules.
	/// Unlike the `whiskrKitSurvey(identifier:)` modifier, the timing is yours to control.
	///
	/// - Parameter surveyId: The identifier of the survey to evaluate and potentially present.
	///
	/// - Note: At least one view in your app's hierarchy must have `.whiskrKit()` or
	///   `.whiskrKitSurvey(identifier:)` attached for the survey to appear.
	///
	/// ## Example: Presenting after sheet dismissal
	/// ```swift
	/// .sheet(isPresented: $showingSettings) {
	///     SettingsView()
	/// }
	/// .onDismiss {
	///     Task {
	///         await WhiskrKit.shared.checkAndPresent(surveyId: "settings-feedback")
	///     }
	/// }
	/// ```
	public func checkAndPresent(surveyId: String) async {
		guard await isEligible(for: surveyId) else { return }
		pendingSurveyId = surveyId
	}

    internal func checkEligibility(for surveyId: String) async -> SurveyTemplate? {
        guard apiKey != nil else {
            Logger.wkCore.critical("WhiskrKit is not initialized with an API key. Call initialize(apiKey:) first.")
            return nil
        }

        return await eligibilityService?.checkEligibility(for: surveyId)
    }

	internal func isEligible(for surveyId: String) async -> Bool {
		await checkEligibility(for: surveyId) != nil
	}

    internal func fetchSurveyTemplate<T>(for identifier: String) async -> T? where T: Decodable {
        guard apiKey != nil else {
            Logger.wkCore.critical("WhiskrKit is not initialized with with an API key. Call initialize(apiKey:) first.")
            return nil
        }
        return try? await configurationService.fetchSurveyTemplate(for: identifier)
    }

    internal func submitSurveyResponse(surveyId: String, response: SurveyResponse) async {
        guard apiKey != nil else {
            Logger.wkCore.error("WhiskrKit is not initialized with with an API key. Call initialize(apiKey:) first.")
            return
        }

        let success = await configurationService.submitSurveyResponse(surveyId: surveyId, response: response)
        if success {
            trackSurveyCompletion(surveyId: surveyId)
        }
    }

    private func trackSurveyCompletion(surveyId: String) {
        var completed = eligibilityStorage.completedSurveys
        completed[surveyId] = Date()
        eligibilityStorage.completedSurveys = completed
        eligibilityStorage.setNextCheckAfter(nil, for: surveyId)
        Logger.wkCore.info("📋 Tracked completion for survey '\(surveyId)'")
    }
}
