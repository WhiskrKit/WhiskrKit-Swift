//
//  PlaygroundCatalog.swift
//  WhiskrKitPlayground
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

// Everything the playground offers is described here as data, so the same
// structure can be mirrored on other platforms. See Examples/PLAYGROUND_SPEC.md.

// MARK: - Surveys

/// A survey the playground can present, backed by one of the SDK's mocked surveys.
struct SurveyDescriptor: Identifiable {
	enum Group: String, CaseIterable {
		case questionTypes = "Question types"
		case presentationStyles = "Presentation styles"
	}

	/// The mocked survey id passed to `WhiskrKit.shared.present(surveyId:)`.
	let id: String
	let name: String
	let summary: String
	let systemImage: String
	let group: Group

	static let all: [SurveyDescriptor] = [
		SurveyDescriptor(
			id: "onboarding-survey",
			name: "Scale rating",
			summary: "Sheet · 1–8 scale with a follow-up question",
			systemImage: "chart.bar",
			group: .questionTypes
		),
		SurveyDescriptor(
			id: "feature-feedback",
			name: "Symbol rating",
			summary: "Sheet · five stars",
			systemImage: "star",
			group: .questionTypes
		),
		SurveyDescriptor(
			id: "checkout-survey",
			name: "Thumbs rating",
			summary: "Sheet · thumbs up or down",
			systemImage: "hand.thumbsup",
			group: .questionTypes
		),
		SurveyDescriptor(
			id: "ask-survey",
			name: "Text feedback",
			summary: "Sheet · free text, 200 characters",
			systemImage: "text.bubble",
			group: .questionTypes
		),
		SurveyDescriptor(
			id: "choice-survey",
			name: "Multiple choice",
			summary: "Sheet · multi-select options",
			systemImage: "checklist",
			group: .questionTypes
		),
		SurveyDescriptor(
			id: "welcome-toast",
			name: "Toast",
			summary: "Thumbs rating, follow-up opens a sheet",
			systemImage: "rectangle.bottomhalf.inset.filled",
			group: .presentationStyles
		),
		SurveyDescriptor(
			id: "super-survey",
			name: "Full-screen form",
			summary: "All question types in one form",
			systemImage: "rectangle.portrait.inset.filled",
			group: .presentationStyles
		),
	]
}

// MARK: - Color roles

/// A themeable color the playground exposes. One role can drive several
/// `WhiskrKitTheme` properties; ``ThemeSettings`` does that mapping.
struct ColorRole: Identifiable, Hashable {
	/// Stable key, used for persistence and shared across platforms.
	let id: String
	let name: String
	let summary: String
	/// The adaptive color used while the role is not customized.
	let systemColor: Color
	/// Swift source for ``systemColor``, used in the code snippet.
	let systemCode: String

	static let accent = ColorRole(
		id: "accent",
		name: "Accent",
		summary: "Primary button background",
		systemColor: Color(.label),
		systemCode: "Color(.label)"
	)
	static let onAccent = ColorRole(
		id: "onAccent",
		name: "On accent",
		summary: "Primary button text",
		systemColor: Color(.systemBackground),
		systemCode: "Color(.systemBackground)"
	)
	static let background = ColorRole(
		id: "background",
		name: "Background",
		summary: "Sheet, form and toast background",
		systemColor: Color(.secondarySystemBackground),
		systemCode: "Color(.secondarySystemBackground)"
	)
	static let text = ColorRole(
		id: "text",
		name: "Text",
		summary: "Titles, body, secondary buttons",
		systemColor: .primary,
		systemCode: "Color.primary"
	)
	static let secondaryText = ColorRole(
		id: "secondaryText",
		name: "Secondary text",
		summary: "Subtitles and subheadlines",
		systemColor: .secondary,
		systemCode: "Color.secondary"
	)
	static let selection = ColorRole(
		id: "selection",
		name: "Selection",
		summary: "Selected multiple-choice options",
		systemColor: Color(.label),
		systemCode: "Color(.label)"
	)

	static let all: [ColorRole] = [accent, onAccent, background, text, secondaryText, selection]

	static func == (lhs: ColorRole, rhs: ColorRole) -> Bool { lhs.id == rhs.id }
	func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Presets

/// A named set of custom colors, keyed by ``ColorRole/id``. Roles left out
/// stay on their adaptive system color.
struct ThemePreset: Identifiable {
	let id: String
	let name: String
	let colors: [String: String]

	/// No custom colors: identical to `WhiskrKitTheme.systemStyle`. Doubles as reset.
	static let system = ThemePreset(id: "system", name: "System", colors: [:])

	/// Brand presets only set the accent roles, so surfaces and text keep
	/// adapting to light and dark mode.
	static let ocean = ThemePreset(
		id: "ocean",
		name: "Ocean",
		colors: ["accent": "#0066CC", "onAccent": "#FFFFFF", "selection": "#0066CC"]
	)
	static let sunset = ThemePreset(
		id: "sunset",
		name: "Sunset",
		colors: ["accent": "#E8590C", "onAccent": "#FFFFFF", "selection": "#E8590C"]
	)

	/// Sets every role, which makes the theme fixed: it looks the same in
	/// light and dark mode.
	static let midnight = ThemePreset(
		id: "midnight",
		name: "Midnight",
		colors: [
			"accent": "#F5C542",
			"onAccent": "#1B1B2F",
			"background": "#1B1B2F",
			"text": "#F2F2F7",
			"secondaryText": "#A5A5C0",
			"selection": "#F5C542",
		]
	)

	static let all: [ThemePreset] = [system, ocean, sunset, midnight]
}
