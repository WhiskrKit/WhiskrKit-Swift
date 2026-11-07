//
//  View+SurveyLanguage.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

extension View {
    /// Shows WhiskrKit's own strings in the language the survey was served in, so
    /// "required", "Submit" and the VoiceOver labels match the survey text. Without
    /// a language from the server, the strings follow the host app's language.
    @ViewBuilder
    func surveyLanguage(_ language: String?) -> some View {
        if let language, !language.isEmpty {
            environment(\.locale, Locale(identifier: language))
        } else {
            self
        }
    }
}

extension LocalizedStringResource {
    /// Resolves the string in `locale` (pass the view's `\.locale`) rather than the
    /// device language, for places that need a plain `String`, like announcements.
    func resolved(in locale: Locale) -> String {
        var resource = self
        resource.locale = locale
        return String(localized: resource)
    }
}
