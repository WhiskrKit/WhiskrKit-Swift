//
//  MockEligibilityService.swift
//  WhiskrKit
//
//  Created by Dennis Vermeulen on 14/03/2026.
//

final class MockEligibilityService: EligibilityService {
	private let configurationService: ConfigurationService

	init(configurationService: ConfigurationService) {
			self.configurationService = configurationService
		}

	func checkEligibility(for surveyId: String) async -> SurveyTemplate? {
		return try? await configurationService.fetchSurveyTemplate(for: surveyId)
	}
}
