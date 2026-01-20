//
//  SurveyResponse.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SurveyResponse: Codable, Equatable {
    var results: [String: SurveyType]

    enum SurveyType: Codable, Equatable {
        case npsRating(Int)
        case symbolRating(Int)
        case thumbsRating(ThumbsRating)
        case textualSurvey(String)

		enum CodingKeys: String, CodingKey {
			  case npsRating
			  case symbolRating
			  case thumbsRating
			  case textualSurvey
		  }

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			switch self {
			case .npsRating(let score):
				try container.encode(score, forKey: .npsRating)
			case .symbolRating(let score):
				try container.encode(score, forKey: .symbolRating)
			case .thumbsRating(let rating):
				try container.encode(rating, forKey: .thumbsRating)
			case .textualSurvey(let feedback):
				try container.encode(feedback, forKey: .textualSurvey)
			}
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			if let score = try container.decodeIfPresent(Int.self, forKey: .npsRating) {
				self = .npsRating(score)
			} else if let score = try container.decodeIfPresent(Int.self, forKey: .symbolRating) {
				self = .symbolRating(score)
			} else if let rating = try container.decodeIfPresent(ThumbsRating.self, forKey: .thumbsRating) {
				self = .thumbsRating(rating)
			} else if let feedback = try container.decodeIfPresent(String.self, forKey: .textualSurvey) {
				self = .textualSurvey(feedback)
			} else {
				throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "No valid survey type found"))
			}
		}
    }
}
