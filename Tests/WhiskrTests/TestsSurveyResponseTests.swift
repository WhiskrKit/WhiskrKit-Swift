//
//  SurveyResponseTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@Suite("Survey Response Tests")
struct SurveyResponseTests {
    
    // MARK: - Initialization Tests
    
    @Test("Survey response initializes correctly")
    func initializesCorrectly() {
        let response = SurveyResponse(
            surveyIdentifier: "test-survey",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        #expect(response.surveyIdentifier == "test-survey")
        #expect(response.results.count == 1)
    }
    
    @Test("Survey response supports multiple result types")
    func supportsMultipleResultTypes() {
        let response = SurveyResponse(
            surveyIdentifier: "test",
            results: [
                "q1": .symbolRating(score: 5),
                "q2": .nspRating(score: 8),
				"q3": .thumbsRating(thumbsRating: .thumbsUp),
                "q4": .textualSurvey(feedback: "Great app!")
            ]
        )
        
        #expect(response.results.count == 4)
        
        // Verify each type
        if case .symbolRating(let score) = response.results["q1"] {
            #expect(score == 5)
        } else {
            Issue.record("Expected symbolRating")
        }
        
        if case .nspRating(let score) = response.results["q2"] {
            #expect(score == 8)
        } else {
            Issue.record("Expected nspRating")
        }
        
        if case .thumbsRating(let rating) = response.results["q3"] {
			#expect(rating == .thumbsUp)
        } else {
            Issue.record("Expected thumbsRating")
        }
        
        if case .textualSurvey(let feedback) = response.results["q4"] {
            #expect(feedback == "Great app!")
        } else {
            Issue.record("Expected textualSurvey")
        }
    }
    
    // MARK: - Codable Tests
    
    @Test("Survey response encodes to JSON correctly")
    func encodesToJSON() throws {
        let response = SurveyResponse(
            surveyIdentifier: "test-survey",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        #expect(data.count > 0)
        
        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["surveyIdentifier"] as? String == "test-survey")
        #expect(json?["results"] != nil)
    }
    
    @Test("Survey response decodes from JSON correctly")
    func decodesFromJSON() throws {
        let jsonString = """
        {
            "surveyIdentifier": "test-survey",
            "results": {
                "q1": {
                    "symbolRating": {
                        "score": 5
                    }
                }
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SurveyResponse.self, from: data)
        
        #expect(response.surveyIdentifier == "test-survey")
        #expect(response.results.count == 1)
        
        if case .symbolRating(let score) = response.results["q1"] {
            #expect(score == 5)
        } else {
            Issue.record("Expected symbolRating")
        }
    }
    
    @Test("Survey response round-trips through encoding and decoding")
    func roundTripEncodingDecoding() throws {
        let original = SurveyResponse(
            surveyIdentifier: "test-survey",
            results: [
                "q1": .symbolRating(score: 5),
                "q2": .nspRating(score: 9),
				"q3": .thumbsRating(thumbsRating: .thumbsDown),
                "q4": .textualSurvey(feedback: "Nice!")
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SurveyResponse.self, from: data)
        
        #expect(decoded == original)
    }
    
    // MARK: - Equatable Tests
    
    @Test("Survey responses with same data are equal")
    func equalityWithSameData() {
        let response1 = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let response2 = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        #expect(response1 == response2)
    }
    
    @Test("Survey responses with different identifiers are not equal")
    func inequalityWithDifferentIdentifiers() {
        let response1 = SurveyResponse(
            surveyIdentifier: "test1",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let response2 = SurveyResponse(
            surveyIdentifier: "test2",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        #expect(response1 != response2)
    }
    
    @Test("Survey responses with different results are not equal")
    func inequalityWithDifferentResults() {
        let response1 = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 5)]
        )
        
        let response2 = SurveyResponse(
            surveyIdentifier: "test",
            results: ["q1": .symbolRating(score: 3)]
        )
        
        #expect(response1 != response2)
    }
    
    // MARK: - Survey Type Tests
    
    @Test("Survey types are equatable")
    func surveyTypesAreEquatable() {
        let type1: SurveyResponse.SurveyType = .symbolRating(score: 5)
        let type2: SurveyResponse.SurveyType = .symbolRating(score: 5)
        let type3: SurveyResponse.SurveyType = .symbolRating(score: 3)
        
        #expect(type1 == type2)
        #expect(type1 != type3)
    }
}
