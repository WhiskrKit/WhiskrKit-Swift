//
//  SurveyCompletion.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// A survey the user just submitted, passed to ``WhiskrKit/onSurveyCompleted``.
public struct SurveyCompletion: Sendable, Equatable {
    /// The id of the survey that was submitted.
    public let surveyId: String
    /// The answers the user gave, ordered by question id. Questions the user
    /// left unanswered are not included.
    public let answers: [Answer]

    public init(surveyId: String, answers: [Answer]) {
        self.surveyId = surveyId
        self.answers = answers
    }

    /// One answered question.
    public struct Answer: Sendable, Equatable {
        public let questionId: String
        public let questionType: QuestionType
        public let value: Value

        public init(questionId: String, questionType: QuestionType, value: Value) {
            self.questionId = questionId
            self.questionType = questionType
            self.value = value
        }
    }

    /// The kind of question that was answered.
    public enum QuestionType: String, Sendable, Equatable {
        case scaleRating
        case symbolRating
        case thumbsRating
        case textualSurvey
        case multipleChoice
    }

    /// The submitted value.
    public enum Value: Sendable, Equatable {
        /// A scale or star rating.
        case score(Int)
        /// A thumbs rating: `true` for thumbs up, `false` for thumbs down.
        case thumbs(isUp: Bool)
        /// Free text.
        case text(String)
        /// The ids of the selected multiple choice options.
        case choices([String])
    }
}

extension SurveyCompletion {
    /// Builds the completion from a submitted response.
    init(surveyId: String, response: SurveyResponse) {
        let answers = response.results
            .compactMap { questionId, result in Answer(questionId: questionId, result: result) }
            .sorted { $0.questionId.localizedStandardCompare($1.questionId) == .orderedAscending }
        self.init(surveyId: surveyId, answers: answers)
    }
}

extension SurveyCompletion.Answer {
    init?(questionId: String, result: SurveyResponse.SurveyType) {
        switch result {
        case .npsRating(let score):
            self.init(questionId: questionId, questionType: .scaleRating, value: .score(score))
        case .symbolRating(let score):
            self.init(questionId: questionId, questionType: .symbolRating, value: .score(score))
        case .thumbsRating(let rating):
            switch rating {
            case .thumbsUp: self.init(questionId: questionId, questionType: .thumbsRating, value: .thumbs(isUp: true))
            case .thumbsDown: self.init(questionId: questionId, questionType: .thumbsRating, value: .thumbs(isUp: false))
            case .none: return nil
            }
        case .textualSurvey(let text):
            self.init(questionId: questionId, questionType: .textualSurvey, value: .text(text))
        case .multipleChoice(let ids):
            self.init(questionId: questionId, questionType: .multipleChoice, value: .choices(ids))
        }
    }
}
