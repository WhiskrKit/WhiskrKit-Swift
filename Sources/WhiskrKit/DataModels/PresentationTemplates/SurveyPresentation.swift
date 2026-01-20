//
//  SurveyPresentation.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SurveyPresentation: Decodable {
    let surveyBase: SurveyBase
    
    enum SurveyType: String, Decodable {
        case scaleRating
        case symbolRating
        case thumbsRating
        case textualSurvey
    }
    
    enum SurveyBase: Decodable {
        case scaleRating(base: ScaleRatingTemplate)
        case symbolRating(base: SymbolRatingTemplate)
        case textualSurvey(base: TextSurveyTemplate)
        case thumbsRating(base: ThumbsSurveyTemplate)
    }
    
    public enum CodingKeys: CodingKey {
        case template
    }
    
    init(surveyBase: SurveyBase) {
        self.surveyBase = surveyBase
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let template = try container.decode(SurveyType.self, forKey: .template)
        switch template {
        case .scaleRating:
            let surveyBase = try ScaleRatingTemplate(from: decoder)
            self.surveyBase = .scaleRating(base: surveyBase)
        case .symbolRating:
            let surveyBase = try SymbolRatingTemplate(from: decoder)
            self.surveyBase = .symbolRating(base: surveyBase)
        case .textualSurvey:
            let surveyBase = try TextSurveyTemplate(from: decoder)
            self.surveyBase = .textualSurvey(base: surveyBase)
        case .thumbsRating:
            let surveyBase = try ThumbsSurveyTemplate(from: decoder)
            self.surveyBase = .thumbsRating(base: surveyBase)
        }
    }
}

extension SurveyPresentation.SurveyBase {
    var isRequired: Bool {
        switch self {
        case .scaleRating(let base): base.isRequired
        case .symbolRating(let base): base.isRequired
        case .textualSurvey(let base): base.isRequired
        case .thumbsRating(let base): base.isRequired
        }
    }
    
    var id: String {
        switch self {
        case .scaleRating(let base): base.id
        case .symbolRating(let base): base.id
        case .textualSurvey(let base): base.id
        case .thumbsRating(let base): base.id
        }
    }
}
