//
//  SurveyCompletionTests.swift
//  WhiskrKitTests
//

import Testing
import Foundation
@testable import WhiskrKit

@MainActor
private final class StubConfigurationService: ConfigurationService {
    let networkService: NetworkService = MockNetworkService()
    var shouldSucceed = true
    var submitCount = 0
    var onSubmit: (() -> Void)?

    func fetchSurveyTemplate<T>(for identifier: String) async throws -> T? where T: Decodable { nil }
    func submitSurveyResponse(surveyId: String, response: SurveyResponse) async -> Bool {
        submitCount += 1
        onSubmit?()
        return shouldSucceed
    }
    func recordImpression(surveyId: String, event: SurveyImpressionEvent, trigger: SurveyImpressionTrigger) async {}
    func retryPendingSubmissions() async {}
    func configure(apiKey: String) {}
}

@MainActor
@Suite("Survey completion callback")
struct SurveyCompletionTests {

    private func makeKit(apiKey: String? = "k") -> (WhiskrKit, StubConfigurationService) {
        let service = StubConfigurationService()
        return (WhiskrKit(configurationService: service, apiKey: apiKey), service)
    }

    @Test("Reports the survey id and every answer with its type and value")
    func reportsAnswers() async {
        let (kit, _) = makeKit()
        var received: [SurveyCompletion] = []
        kit.onSurveyCompleted = { received.append($0) }

        await kit.submitSurveyResponse(surveyId: "s1", response: SurveyResponse(results: [
            "s1-q10": .multipleChoice(["a", "c"]),
            "s1-q2": .symbolRating(4),
            "s1-q1": .npsRating(9),
            "s1-q3": .thumbsRating(.thumbsDown),
            "s1-q4": .textualSurvey("Great"),
        ]))

        #expect(received == [SurveyCompletion(surveyId: "s1", answers: [
            .init(questionId: "s1-q1", questionType: .scaleRating, value: .score(9)),
            .init(questionId: "s1-q2", questionType: .symbolRating, value: .score(4)),
            .init(questionId: "s1-q3", questionType: .thumbsRating, value: .thumbs(isUp: false)),
            .init(questionId: "s1-q4", questionType: .textualSurvey, value: .text("Great")),
            .init(questionId: "s1-q10", questionType: .multipleChoice, value: .choices(["a", "c"])),
        ])])
    }

    @Test("Fires when the submission fails")
    func firesOnFailedSubmission() async {
        let (kit, service) = makeKit()
        service.shouldSucceed = false
        var count = 0
        kit.onSurveyCompleted = { _ in count += 1 }

        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: ["q": .symbolRating(2)]))

        #expect(count == 1)
    }

    @Test("Fires before the network submission")
    func firesBeforeNetwork() async {
        let (kit, service) = makeKit()
        var events: [String] = []
        kit.onSurveyCompleted = { _ in events.append("callback") }
        service.onSubmit = { events.append("network") }

        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: ["q": .npsRating(5)]))

        #expect(events == ["callback", "network"])
    }

    @Test("Fires once per submission")
    func firesOncePerSubmission() async {
        let (kit, _) = makeKit()
        var ids: [String] = []
        kit.onSurveyCompleted = { ids.append($0.surveyId) }

        await kit.submitSurveyResponse(surveyId: "a", response: SurveyResponse(results: [:]))
        await kit.submitSurveyResponse(surveyId: "b", response: SurveyResponse(results: [:]))

        #expect(ids == ["a", "b"])
    }

    @Test("Does not fire before WhiskrKit is initialized")
    func notInitialized() async {
        let (kit, service) = makeKit(apiKey: nil)
        var count = 0
        kit.onSurveyCompleted = { _ in count += 1 }

        await kit.submitSurveyResponse(surveyId: "s", response: SurveyResponse(results: ["q": .npsRating(5)]))

        #expect(count == 0)
        #expect(service.submitCount == 0)
    }

    @Test("A thumbs question without a choice is left out")
    func unansweredThumbsLeftOut() {
        let completion = SurveyCompletion(surveyId: "s", response: SurveyResponse(results: ["q": .thumbsRating(.none)]))
        #expect(completion.answers.isEmpty)
    }

    @Test("Star questions that still carry opensStoreReview decode")
    func ignoresLegacyStoreReviewKey() throws {
        let json = """
        { "id": "q1", "title": "Rate", "opensStoreReview": true, "isRequired": false }
        """
        let template = try JSONDecoder().decode(SymbolRatingTemplate.self, from: Data(json.utf8))
        #expect(template.id == "q1")
    }
}
