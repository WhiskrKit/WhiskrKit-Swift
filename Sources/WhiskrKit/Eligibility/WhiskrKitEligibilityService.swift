//
//  EligibilityService.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

protocol EligibilityService {
	func checkEligibility(for surveyId: String) async -> SurveyTemplate?
}

/// Manages per-survey eligibility checks.
///
/// All methods run on the `@MainActor`, which ensures that the in-flight set
/// is checked and modified atomically around every `await` suspension point —
/// preventing duplicate network calls when the same survey identifier appears
/// on multiple views simultaneously.
@MainActor
final class WhiskrKitEligibilityService: EligibilityService {

    private let networkService: NetworkService
    private let storage: any EligibilityStorage

    /// Survey IDs for which an eligibility network call is currently in-flight.
    private var inFlightSurveyIds: Set<String> = []

    init(networkService: NetworkService, storage: any EligibilityStorage) {
        self.networkService = networkService
        self.storage = storage
    }

    /// Checks whether `surveyId` should be shown to the current user.
    ///
    /// Returns the `SurveyTemplate` to display, or `nil` if the survey should
    /// not be shown (cache hit, server declined, or network failure).
    func checkEligibility(for surveyId: String) async -> SurveyTemplate? {
        // 1. Deduplicate: skip if already in-flight
        guard !inFlightSurveyIds.contains(surveyId) else {
            Logger.wkNetworking.info("⏳ Eligibility check already in-flight for '\(surveyId)', skipping.")
            return nil
        }

        // 2. Respect nextCheckAfter cache
        if let nextCheck = storage.nextCheckAfter(for: surveyId), nextCheck > Date() {
            Logger.wkNetworking.info("⏭️ Skipping eligibility check for '\(surveyId)' until \(nextCheck).")
            return nil
        }

        // 3. Mark in-flight
        inFlightSurveyIds.insert(surveyId)
        defer { inFlightSurveyIds.remove(surveyId) }

        // 4. Build context
        let context = buildContext()

        // 5. Call server
        do {
            let response = try await networkService.checkEligibility(surveyId: surveyId, context: context)

            // 6. Persist nextCheckAfter hint
            storage.setNextCheckAfter(response.nextCheckAfter, for: surveyId)

            // 6b. Handle removeFromHistory
            if response.removeFromHistory == true {
                storage.removeCompletedSurvey(surveyId)
                storage.setNextCheckAfter(nil, for: surveyId)
            }

            // 7. Present if eligible
            if response.shouldShow, let survey = response.survey {
                storage.lastSurveyDate = Date()
                Logger.wkNetworking.info("✅ Eligibility granted for '\(surveyId)'.")
                return survey
            }

            Logger.wkNetworking.info("🚫 Server declined eligibility for '\(surveyId)'.")
        } catch {
            // Fail silently — never crash the host app
            Logger.wkNetworking.warning("⚠️ Eligibility check failed for '\(surveyId)': \(error). Showing nothing.")
        }

        return nil
    }

    // MARK: - Private

    private func buildContext() -> SurveyEligibilityContext {
        SurveyEligibilityContext(
            deviceId: storage.deviceId,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            locale: Locale.current.identifier,
            sessionCount: storage.sessionCount,
            installDate: storage.installDate,
            lastSurveyDate: storage.lastSurveyDate,
            completedSurveys: storage.completedSurveys
        )
    }
}
