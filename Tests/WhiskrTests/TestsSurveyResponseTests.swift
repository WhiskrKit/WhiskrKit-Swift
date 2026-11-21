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
            results: ["q1": .symbolRating(5)]
        )

        #expect(response.results.count == 1)
    }
    
    @Test("Survey response supports multiple result types")
    func supportsMultipleResultTypes() {
        let response = SurveyResponse(
            results: [
                "q1": .symbolRating(5),
				"q2": .scaleRating(8),
				"q3": .thumbsRating(.thumbsUp),
                "q4": .textualSurvey("Great app!")
            ]
        )
        
        #expect(response.results.count == 4)
        
        // Verify each type
        if case .symbolRating(let score) = response.results["q1"] {
            #expect(score == 5)
        } else {
            Issue.record("Expected symbolRating")
        }
        
		if case .scaleRating(let score) = response.results["q2"] {
            #expect(score == 8)
        } else {
            Issue.record("Expected scaleRating")
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
            results: ["q1": .symbolRating(5)]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        #expect(data.count > 0)
        
        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["results"] != nil)
    }
    
    @Test("Survey response decodes from JSON correctly")
    func decodesFromJSON() throws {
        let jsonString = """
        {
            "results": {
                "q1": {
                    "symbolRating": 5
                }
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SurveyResponse.self, from: data)

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
            results: [
                "q1": .symbolRating(5),
                "q2": .scaleRating(9),
				"q3": .thumbsRating(.thumbsDown),
                "q4": .textualSurvey("Nice!")
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
            results: ["q1": .symbolRating(5)]
        )
        
        let response2 = SurveyResponse(
            results: ["q1": .symbolRating(5)]
        )
        
        #expect(response1 == response2)
    }

    
    @Test("Survey responses with different results are not equal")
    func inequalityWithDifferentResults() {
        let response1 = SurveyResponse(
            results: ["q1": .symbolRating(5)]
        )
        
        let response2 = SurveyResponse(
            results: ["q1": .symbolRating(3)]
        )
        
        #expect(response1 != response2)
    }
    
    // MARK: - Survey Type Tests
    
    @Test("Survey types are equatable")
    func surveyTypesAreEquatable() {
        let type1: SurveyResponse.SurveyType = .symbolRating(5)
        let type2: SurveyResponse.SurveyType = .symbolRating(5)
        let type3: SurveyResponse.SurveyType = .symbolRating(3)
        
        #expect(type1 == type2)
        #expect(type1 != type3)
    }

    // MARK: - Scale rating

    @Test("Selecting a score stores it")
    func scaleRatingSelectStores() {
        var response = SurveyResponse(results: [:])
        response.setScaleRating(8, for: "q1")
        #expect(response.results["q1"] == .scaleRating(8))
    }

    @Test("Deselecting a score removes the answer")
    func scaleRatingDeselectRemoves() {
        var response = SurveyResponse(results: ["q2": .textualSurvey("Keep me")])
        response.setScaleRating(8, for: "q1")
        response.setScaleRating(nil, for: "q1")
        #expect(response.results["q1"] == nil)
        #expect(response.results["q2"] == .textualSurvey("Keep me"))
    }

    @Test("A scale rating encodes exactly as before the rename")
    func scaleRatingWireFormatIsUnchanged() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(SurveyResponse(results: ["q1": .scaleRating(8)]))
        #expect(String(decoding: data, as: UTF8.self) == #"{"results":{"q1":{"npsRating":8}}}"#)
    }

    @Test("A stored scale rating from before the rename still decodes")
    func storedScaleRatingDecodes() throws {
        let data = Data(#"{"results":{"q1":{"npsRating":3}}}"#.utf8)
        let response = try JSONDecoder().decode(SurveyResponse.self, from: data)
        #expect(response.results["q1"] == .scaleRating(3))
    }
}
