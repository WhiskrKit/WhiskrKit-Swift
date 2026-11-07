//
//  LocalizationTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import SwiftUI
import Testing
@testable import WhiskrKit

@Suite("Localization")
struct LocalizationTests {

    // MARK: - String catalog

    /// Every SDK string must be translated into every language the catalog ships,
    /// otherwise that language silently falls back to English for that string.
    @Test("Every catalog string is translated into every shipped language")
    func catalogIsComplete() throws {
        let catalogURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../Sources/WhiskrKit/Localizable.xcstrings")
            .standardized
        let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: catalogURL)) as? [String: Any]
        let strings = try #require(catalog?["strings"] as? [String: [String: Any]])

        let sdkStrings = strings.filter { $0.value["extractionState"] as? String == "manual" }
        let languages = Set(sdkStrings.values.flatMap { ($0["localizations"] as? [String: Any])?.keys ?? [:].keys })
        #expect(languages.count > 1)

        for (key, entry) in sdkStrings {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            for language in languages {
                let value = (localizations[language]?["stringUnit"] as? [String: Any])?["value"] as? String
                #expect(value?.isEmpty == false, "\(key) has no \(language) translation")
            }
        }
    }

    // MARK: - Survey language

    @Test("Decodes the language a survey was served in")
    func decodesLanguage() throws {
        let json = """
        { "template": "toast", "id": "t1", "title": "Hoi", "followUpIdentifier": "f1", "language": "nl" }
        """
        let template = try JSONDecoder().decode(ToastTemplate.self, from: Data(json.utf8))
        #expect(template.language == "nl")
    }

    @Test("A survey without a language decodes as before")
    func decodesMissingLanguage() throws {
        let json = """
        { "template": "toast", "id": "t1", "title": "Hi", "followUpIdentifier": "f1" }
        """
        let template = try JSONDecoder().decode(ToastTemplate.self, from: Data(json.utf8))
        #expect(template.language == nil)
    }

    @MainActor
    @Test("surveyLanguage renders WhiskrKit's strings in the survey's language")
    func rendersInSurveyLanguage() {
        let english = render(Text(verbatim: "required"))
        let german = render(Text(.requiredFieldLabel).surveyLanguage("de"))

        #expect(german == render(Text(verbatim: "erforderlich")))
        #expect(german != english)
        // CJK typesetting differs slightly between localized and verbatim text, so only
        // check that it changed; `resolvesInLocale` checks the exact Japanese string.
        #expect(render(Text(.requiredFieldLabel).surveyLanguage("ja")) != english)
        #expect(
            render(Text(.requiredFieldLabel).surveyLanguage(nil).environment(\.locale, Locale(identifier: "en")))
            == english
        )
    }

    @Test("Resolves announcement strings in a given locale")
    func resolvesInLocale() {
        #expect(LocalizedStringResource.requiredFieldLabel.resolved(in: Locale(identifier: "nl")) == "verplicht")
        #expect(LocalizedStringResource.requiredFieldLabel.resolved(in: Locale(identifier: "ja")) == "必須")
        #expect(LocalizedStringResource.accessibilityXOutOfYSymbolLabel(3, stars: 5).resolved(in: Locale(identifier: "nl")) == "3 van 5 sterren")
    }

    /// The server sends two-letter codes, which must still find the pt-BR and zh-Hans translations.
    @Test("Two-letter codes from the server find the regional translations")
    func resolvesTwoLetterCodes() {
        #expect(LocalizedStringResource.requiredFieldLabel.resolved(in: Locale(identifier: "pt")) == "obrigatório")
        #expect(LocalizedStringResource.requiredFieldLabel.resolved(in: Locale(identifier: "zh")) == "必填")
    }

    @MainActor
    private func render(_ view: some View) -> Data? {
        ImageRenderer(content: view.fixedSize()).uiImage?.pngData()
    }
}
