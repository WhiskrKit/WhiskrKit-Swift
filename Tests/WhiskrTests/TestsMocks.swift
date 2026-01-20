//
//  Mocks.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 17/12/2025.
//

import Foundation
@testable import WhiskrKit

// MARK: - Mock Network Service

final class MockNetworkService: NetworkService {
    var submitCallCount = 0
    var shouldFail = false
    var fetchCallCount = 0
    var delaySeconds: TimeInterval = 0
    var lastIdempotencyKey: String?
    
    init() {
        super.init(baseURL: URL(string: "https://test.example.com")!)
    }
    
    override func submitRating(
        surveyId: String,
        identifier: String,
        surveyResponse: SurveyResponse,
        idempotencyKey: String? = nil
    ) async throws {
        // Capture the idempotency key
        lastIdempotencyKey = idempotencyKey
        
        // Apply delay if configured
        if delaySeconds > 0 {
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }
        
        submitCallCount += 1
        
        if shouldFail {
            throw WhiskrKitError.networkError(NSError(domain: "test", code: -1))
        }
        
        // Success - no-op
    }
    
    override func fetchSurvey<T: Decodable>(identifier: String) async throws -> T {
        fetchCallCount += 1
        
        if shouldFail {
            throw WhiskrKitError.networkError(NSError(domain: "test", code: -1))
        }
        
        // Return a mock response - this will fail if T isn't compatible
        // For basic testing, this should be sufficient
        throw WhiskrKitError.notFound
    }
}

// MARK: - Mock Submission Storage

final class MockSubmissionStorage: SubmissionStorage {
    var storedSubmissions: [PendingSubmission] = []
    var saveCallCount = 0
    var loadCallCount = 0
    var clearCallCount = 0
    var lastSavedSubmissions: [PendingSubmission]?
    
    func save(_ submissions: [PendingSubmission]) {
        saveCallCount += 1
        lastSavedSubmissions = submissions
        storedSubmissions = submissions
    }
    
    func load() -> [PendingSubmission] {
        loadCallCount += 1
        return storedSubmissions
    }
    
    func clear() {
        clearCallCount += 1
        storedSubmissions = []
    }
}

// MARK: - Mock Survey Template

struct MockSurveyTemplate: Decodable {
    let id: String
    let title: String
}
