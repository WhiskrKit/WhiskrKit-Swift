//
//  WhiskrKitErrorTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@Suite("WhiskrKit Error Tests")
struct WhiskrKitErrorTests {
    
    // MARK: - Error Type Tests
    
    @Test("WhiskrKit error types exist")
    func errorTypesExist() {
        let errors: [WhiskrKitError] = [
            .notInitialized,
            .unauthorized,
            .forbidden,
            .notFound,
            .badRequest,
            .rateLimited,
            .serverError,
            .networkError(URLError(.notConnectedToInternet)),
            .invalidResponse,
            .decodingFailed(NSError(domain: "test", code: 0)),
            .submissionFailed,
            .httpError(statusCode: 418)
        ]
        
        #expect(errors.count == 12)
    }
    
    @Test("Network error wraps underlying error")
    func networkErrorWrapsUnderlyingError() {
        let underlyingError = URLError(.timedOut)
        let error = WhiskrKitError.networkError(underlyingError)
        
        if case .networkError(let wrapped) = error {
            #expect((wrapped as? URLError)?.code == .timedOut)
        } else {
            Issue.record("Expected networkError case")
        }
    }
    
    @Test("Decoding error wraps underlying error")
    func decodingErrorWrapsUnderlyingError() {
        let underlyingError = NSError(domain: "DecodingError", code: 1)
        let error = WhiskrKitError.decodingFailed(underlyingError)
        
        if case .decodingFailed(let wrapped) = error {
            #expect((wrapped as NSError).domain == "DecodingError")
        } else {
            Issue.record("Expected decodingFailed case")
        }
    }
    
    @Test("HTTP error includes status code")
    func httpErrorIncludesStatusCode() {
        let error = WhiskrKitError.httpError(statusCode: 418)
        
        if case .httpError(let statusCode) = error {
            #expect(statusCode == 418)
        } else {
            Issue.record("Expected httpError case")
        }
    }
    
    // MARK: - Error Matching Tests
    
    @Test("Errors can be matched in switch statements")
    func errorsCanBeMatchedInSwitch() {
        let error = WhiskrKitError.unauthorized
        
        var matched = false
        switch error {
        case .unauthorized:
            matched = true
        default:
            matched = false
        }
        
        #expect(matched)
    }
    
    @Test("Associated values can be extracted")
    func associatedValuesCanBeExtracted() {
        let statusCode = 404
        let error = WhiskrKitError.httpError(statusCode: statusCode)
        
        if case .httpError(let extracted) = error {
            #expect(extracted == statusCode)
        } else {
            Issue.record("Failed to extract associated value")
        }
    }
}
