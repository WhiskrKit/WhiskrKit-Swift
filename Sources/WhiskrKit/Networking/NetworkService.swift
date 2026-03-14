//
//  NetworkService.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import UIKit

class NetworkService {
    private let baseURL: URL
    private var apiKey: String?
    private let urlSession: URLSession
    
    // Configuration
    private let maxRetries = 2
    private let retryDelay: TimeInterval = 1.0
    private let requestTimeout: TimeInterval = 30.0
    
    init(
        baseURL: URL,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchSurvey<T: Decodable>(identifier: String) async throws -> T {
        guard let apiKey = apiKey else {
            throw WhiskrKitError.notInitialized
        }
        
        let url = baseURL.appendingPathComponent("api/v1/survey/\(identifier)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = requestTimeout
        
        // Common headers
        addCommonHeaders(to: &request, apiKey: apiKey)
        
        return try await performGetRequest(request, type: T.self)
    }
    
    func checkEligibility(
        surveyId: String,
        context: SurveyEligibilityContext
    ) async throws -> SurveyEligibilityResponse {
        guard let apiKey = apiKey else {
            throw WhiskrKitError.notInitialized
        }

        let url = baseURL.appendingPathComponent("api/v1/survey/\(surveyId)/eligible")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout

        addCommonHeaders(to: &request, apiKey: apiKey)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(context)

        return try await performPostRequestWithResponse(request, type: SurveyEligibilityResponse.self)
    }

    func submitRating(
        surveyId: String,
        identifier: String,
        surveyResponse: SurveyResponse,
        idempotencyKey: String? = nil
    ) async throws {
        guard let apiKey = apiKey else {
            throw WhiskrKitError.notInitialized
        }
        
        let url = baseURL.appendingPathComponent("api/v1/survey/\(surveyId)/submit")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = requestTimeout
        
        // Common headers
        addCommonHeaders(to: &request, apiKey: apiKey)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "X-Idempotency-Key")
        }
        
        // Body
        request.httpBody = try JSONEncoder().encode(surveyResponse)
        
        try await performPostRequest(request)
	}
    
    // MARK: - GET Request Handler
    
    private func performGetRequest<T: Decodable>(
        _ request: URLRequest,
        type: T.Type,
        attempt: Int = 0
    ) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WhiskrKitError.invalidResponse
            }
            
            // Handle status codes
            try handleStatusCode(httpResponse.statusCode, isRetryable: true)
            
            // Decode response
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw WhiskrKitError.decodingFailed(error)
            }
            
        } catch let error as WhiskrKitError {
            // Check if error is retryable
            if shouldRetry(error: error, attempt: attempt) {
                let backoffDelay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                return try await performGetRequest(request, type: type, attempt: attempt + 1)
            }
            throw error
            
        } catch {
            // Network errors (timeout, no connection)
            if attempt < maxRetries {
                let backoffDelay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                return try await performGetRequest(request, type: type, attempt: attempt + 1)
            }
            throw WhiskrKitError.networkError(error)
        }
    }
    
    // MARK: - POST Request Handler
    
    private func performPostRequest(
        _ request: URLRequest,
        attempt: Int = 0
    ) async throws {
        do {
            let (_, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WhiskrKitError.invalidResponse
            }
            
            try handleStatusCode(httpResponse.statusCode, isRetryable: false)
            
        } catch let error as WhiskrKitError {
            // Only retry on specific errors (NOT on 4xx client errors)
            if shouldRetryPost(error: error, attempt: attempt) {
                let backoffDelay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                return try await performPostRequest(request, attempt: attempt + 1)
            }
            throw error
        } catch {
            // Network errors only (timeout, no connection)
            if attempt < maxRetries {
                let backoffDelay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                return try await performPostRequest(request, attempt: attempt + 1)
            }
            throw WhiskrKitError.networkError(error)
        }
    }
    
    // MARK: - POST Request Handler with Response Body

    private func performPostRequestWithResponse<T: Decodable>(
        _ request: URLRequest,
        type: T.Type,
        attempt: Int = 0
    ) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw WhiskrKitError.invalidResponse
            }

            try handleStatusCode(httpResponse.statusCode, isRetryable: false)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw WhiskrKitError.decodingFailed(error)
            }

        } catch let error as WhiskrKitError {
            if shouldRetryPost(error: error, attempt: attempt) {
                let backoffDelay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                return try await performPostRequestWithResponse(request, type: type, attempt: attempt + 1)
            }
            throw error
        } catch {
            if attempt < maxRetries {
                let backoffDelay = calculateBackoff(attempt: attempt)
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                return try await performPostRequestWithResponse(request, type: type, attempt: attempt + 1)
            }
            throw WhiskrKitError.networkError(error)
        }
    }

    // MARK: - Helper Methods
    
    private func addCommonHeaders(to request: inout URLRequest, apiKey: String) {
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Locale.current.identifier, forHTTPHeaderField: "Accept-Language")
        
        // Device identification (vendor-specific, resets on reinstall)
        request.setValue(UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                         forHTTPHeaderField: "X-Device-ID")
        
        // Host app information
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            request.setValue(bundleIdentifier, forHTTPHeaderField: "X-App-Bundle-ID")
        }
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            request.setValue(appVersion, forHTTPHeaderField: "X-App-Version")
        }
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            request.setValue(buildNumber, forHTTPHeaderField: "X-App-Build")
        }
        
        // Device information
        request.setValue(UIDevice.current.systemName, forHTTPHeaderField: "X-OS-Name") // "iOS" or "iPadOS"
        request.setValue(UIDevice.current.systemVersion, forHTTPHeaderField: "X-OS-Version") // e.g., "17.1"
        request.setValue(UIDevice.current.model, forHTTPHeaderField: "X-Device-Model") // e.g., "iPhone", "iPad"
        request.setValue(deviceModelIdentifier(), forHTTPHeaderField: "X-Device-Identifier") // e.g., "iPhone14,2"
        
        // Locale and timezone (non-identifiable but useful for analytics)
        request.setValue(Locale.current.language.languageCode?.identifier ?? "unknown", forHTTPHeaderField: "X-Language")
        request.setValue(Locale.current.region?.identifier ?? "unknown", forHTTPHeaderField: "X-Region")
        request.setValue(TimeZone.current.identifier, forHTTPHeaderField: "X-Timezone")
        
        // User agent with framework version
        let frameworkVersion = frameworkVersion
        request.setValue("WhiskrKit-ios/\(frameworkVersion)", forHTTPHeaderField: "User-Agent")
        
        request.cachePolicy = .reloadIgnoringLocalCacheData
    }
    
    /// Returns the specific device model identifier (e.g., "iPhone14,2" for iPhone 13 Pro)
    private func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

	private var frameworkVersion: String {
		Bundle(for: WhiskrKit.self)
			.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
	}

    private func handleStatusCode(_ statusCode: Int, isRetryable: Bool) throws {
        switch statusCode {
        case 200...299: return
        case 400: throw WhiskrKitError.badRequest
        case 401: throw WhiskrKitError.unauthorized
        case 403: throw WhiskrKitError.forbidden
        case 404: throw WhiskrKitError.notFound
        case 429: throw WhiskrKitError.rateLimited // Retryable
        case 500...599: throw WhiskrKitError.serverError // Retryable
        default: throw WhiskrKitError.httpError(statusCode: statusCode)
        }
    }
    
    private func shouldRetry(error: WhiskrKitError, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        
        switch error {
        case .rateLimited, .serverError: return true
        case .networkError: return true
        default: return false
        }
    }
    
    private func shouldRetryPost(error: WhiskrKitError, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        
        switch error {
        case .rateLimited: return true
        case .serverError: return true
        case .networkError: return true
        default: return false
        }
    }
    
    private func calculateBackoff(attempt: Int) -> TimeInterval {
        // Exponential backoff: 1s, 2s, 4s, 8s...
        return retryDelay * pow(2.0, Double(attempt))
    }
}
