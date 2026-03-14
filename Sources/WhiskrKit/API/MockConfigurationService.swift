//
//  MockConfigurationService.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

/// A mock configuration service for testing and development purposes.
/// Returns predefined survey templates based on identifier strings.
final class MockConfigurationService: ConfigurationService {
    func retryPendingSubmissions() async {
        // Since this is a mock, not really applicable here
    }

    @discardableResult
    func submitSurveyResponse(surveyId: String, response: SurveyResponse) async -> Bool {
        Logger.wkNetworking.info("💾 User saved the following information: surveyId: \(surveyId) response: \(response.results)")
        return true
    }

    let networkService: NetworkService

    private var templates: [String: SurveyTemplate] = [:]
    private var inlineTemplates: [String: SurveyPresentation] = [:]

    init(networkService: NetworkService = NetworkService(baseURL: URL(string: "https://mock.WhiskrKit.eu")!)) {
        self.networkService = networkService
        setupMockTemplates()
    }

    func configure(apiKey: String) {
        // Mock service doesn't need real API configuration
        networkService.configure(apiKey: apiKey)
    }

    func fetchSurveyTemplate<T>(for identifier: String) async throws -> T? where T: Decodable {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        print("count", inlineTemplates.count)
        // Return the template if it exists, nil otherwise
        return templates[identifier] as? T //?? inlineTemplates[identifier] as? T
    }

    // MARK: - Mock Template Setup

    private func setupMockTemplates() {
        // Toast Templates
        templates["welcome-toast"] = createToastTemplate(
            id: "toast-1",
            title: "Welcome to our app!",
            description: "How are you liking it so far?",
            surveyType: .thumbsRating
        )

        templates["quick-feedback"] = createToastTemplate(
            id: "toast-2",
            title: "Quick feedback",
            description: "Rate your experience",
            surveyType: .symbolRating
        )

        templates["simple-toast"] = createToastTemplate(
            id: "toast-3",
            title: "Thanks for using our app!",
            description: nil,
            surveyType: nil
        )

        // Sheet Templates
        templates["onboarding-survey"] = createSheetTemplate(
            id: "sheet-1",
            title: "Welcome aboard!",
            description: "Help us understand your needs better",
            writtenFollowUp: true,
            surveyType: .scaleRating
        )

        templates["feature-feedback"] = createSheetTemplate(
            id: "sheet-2",
            title: "New Feature Feedback",
            description: "What do you think of our latest update?",
            writtenFollowUp: true,
            surveyType: .symbolRating
        )

        templates["checkout-survey"] = createSheetTemplate(
            id: "sheet-3",
            title: "How was your checkout?",
            description: "We'd love to hear your thoughts",
            writtenFollowUp: true,
            surveyType: .thumbsRating
        )

        templates["ask-survey"] = createSheetTemplate(
            id: "sheet-4",
            title: "What would you ask us?",
            description: "We'd love to hear your thoughts about your car's extended warranty",
            writtenFollowUp: false,
            surveyType: .textualSurvey
        )

        // Full Screen Form Templates
        templates["detailed-survey"] = createFullScreenFormTemplate(
            id: "form-1",
            title: "User Experience Survey",
            subtitle: "Help us improve",
            description: "Your feedback shapes our product",
            surveyTypes: [.scaleRating, .symbolRating, .textualSurvey]
        )

        templates["onboarding-questionnaire"] = createFullScreenFormTemplate(
            id: "form-2",
            title: "Tell us about yourself",
            subtitle: "This will only take a minute",
            description: "We use this information to personalize your experience",
            surveyTypes: [.textualSurvey, .thumbsRating]
        )

        templates["satisfaction-survey"] = createFullScreenFormTemplate(
            id: "form-3",
            title: "Overall Satisfaction",
            subtitle: "Annual Customer Survey",
            description: "Thank you for being a valued customer",
            surveyTypes: [.scaleRating, .textualSurvey, .symbolRating, .thumbsRating]
        )

        inlineTemplates["inline-nps"] = createSurveyPresentation(type: .scaleRating, id: "nps-1")
    }

    // MARK: - Template Creation Helpers

    private func createToastTemplate(
        id: String,
        title: String?,
        description: String?,
        surveyType: SurveyPresentation.SurveyType?
    ) -> SurveyTemplate {
        let survey: SurveyPresentation? = {
            guard let surveyType else { return nil }
            return createSurveyPresentation(type: surveyType, id: "\(id)-survey")
        }()

        let toastTemplate = ToastTemplate(
            id: id,
            title: title,
            description: description,
            followUpIdentifier: "onboarding-survey",
            survey: survey
        )

        return SurveyTemplate(
            presentationBase: .toast(base: toastTemplate)
        )
    }

    private func createSheetTemplate(
        id: String,
        title: String?,
        description: String?,
        writtenFollowUp: Bool,
        surveyType: SurveyPresentation.SurveyType
    ) -> SurveyTemplate {
        let survey = createSurveyPresentation(type: surveyType, id: "\(id)-survey")

        let sheetTemplate = SheetTemplate(
            id: id,
            title: title,
            description: description,
            writtenFollowUp: writtenFollowUp,
            survey: survey
        )

        return SurveyTemplate(
            presentationBase: .sheet(base: sheetTemplate)
        )
    }

    private func createFullScreenFormTemplate(
        id: String,
        title: String?,
        subtitle: String?,
        description: String?,
        surveyTypes: [SurveyPresentation.SurveyType]
    ) -> SurveyTemplate {
        let surveys = surveyTypes.enumerated().map { index, type in
            createSurveyPresentation(type: type, id: "\(id)-survey-\(index)")
        }

        let formTemplate = FullScreenFormTemplate(
            id: id,
            title: title,
            subtitle: subtitle,
            description: description,
            surveys: surveys
        )

        return SurveyTemplate(
            presentationBase: .fullScreenForm(base: formTemplate)
        )
    }

    private func createSurveyPresentation(
        type: SurveyPresentation.SurveyType,
        id: String
    ) -> SurveyPresentation {
        let surveyBase: SurveyPresentation.SurveyBase

        switch type {
        case .scaleRating:
            surveyBase = .scaleRating(
                base: ScaleRatingTemplate(
                    id: id,
                    title: "How likely are you to recommend us?",
                    subtitle: "0 = Not at all likely, 8 = Extremely likely",
                    ratingRange: .init(min: 1, max: 8),
                    isRequired: true,
                    A11yLabel: nil,
                    A11yHint: nil
                )
            )
        case .symbolRating:
            surveyBase = .symbolRating(
                base: SymbolRatingTemplate(
                    id: id,
                    title: "Rate your experience",
                    description: "Tap the stars to rate",
                    opensStoreReview: false,
                    isRequired: false,
                    A11yLabel: nil,
                    A11yHint: nil
                )
            )
        case .textualSurvey:
            surveyBase = .textualSurvey(base: TextSurveyTemplate(
                id: id,
                title: "Tell us more",
                description: "Your detailed feedback helps us improve",
                maxLength: 200,
                isRequired: true,
                A11yLabel: nil,
                a11yHint: nil
            ))
        case .thumbsRating:
            surveyBase = .thumbsRating(base: ThumbsSurveyTemplate(
                id: id,
                title: nil,
                subtitle: nil,
                isRequired: false,
                A11yLabel: nil,
                A11yHint: nil
            ))
        }

        return SurveyPresentation(surveyBase: surveyBase)
    }
}
