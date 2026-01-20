//
//  ConfigurationService.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

protocol ConfigurationService {
    var networkService: NetworkService { get }
    func fetchSurveyTemplate<T>(for identifier: String) async throws -> T? where T: Decodable
    func submitSurveyResponse(surveyId: String, response: SurveyResponse) async
    func retryPendingSubmissions() async
    func configure(apiKey: String)
}

final class WhiskrKitConfigurationService: ConfigurationService {
    let networkService: NetworkService

    let submissionQueue: SubmissionQueue
    let retryCoordinator: SubmissionRetryCoordinator

    init(
        networkService: NetworkService = NetworkService(
            baseURL: URL(string: "http://localhost:8080")!
        ),
        submissionQueue: SubmissionQueue = SubmissionQueue()
    ) {
        self.networkService = networkService
        self.submissionQueue = submissionQueue
        self.retryCoordinator = SubmissionRetryCoordinator(
            queue: submissionQueue,
            networkService: networkService
        )
    }

    public func configure(apiKey: String) {
        networkService.configure(apiKey: apiKey)

        Task {
            await retryPendingSubmissions()
        }
    }

    func retryPendingSubmissions() async {
        await retryCoordinator.retryPendingSubmissions()
    }

    func fetchSurveyTemplate<T>(for identifier: String) async throws ->  T? where T: Decodable {
		do {
			return try await networkService.fetchSurvey(identifier: identifier)
		} catch {
			Logger.wkNetworking.warning("❌Fetching survey failed: \(error)")
			return nil
		}
    }

    func submitSurveyResponse(surveyId: String, response: SurveyResponse) async {
        await retryPendingSubmissions()
        do {
            try await networkService.submitRating(
                surveyId: surveyId,
                identifier: "", // TODO: - Consider the usage of this argument
                surveyResponse: response
            )
            Logger.wkNetworking.info("✅ Survey response submitted successfully")
        } catch {
            Logger.wkNetworking.warning("❌ Submission failed, adding to queue: \(error)")

            let pending = PendingSubmission(
                surveyId: surveyId,
                response: response
            )

            submissionQueue.enqueue(pending)
        }
    }
}
