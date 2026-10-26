//
//  ThemeSettings.swift
//  WhiskrKitPlayground
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import WhiskrKit

/// The playground's theme colors. Every change is saved to UserDefaults and
/// applied with `WhiskrKit.shared.setTheme(_:)`, so the next survey uses it.
@Observable
final class ThemeSettings {
	static let storageKey = "whiskrkit.playground.colors"

	/// Custom colors keyed by ``ColorRole/id``. A role without an entry uses
	/// its adaptive system color.
	private(set) var customColors: [String: HexColor] {
		didSet {
			save()
			WhiskrKit.shared.setTheme(theme)
		}
	}

	@ObservationIgnored private let defaults: UserDefaults

	init(defaults: UserDefaults = .standard) {
		self.defaults = defaults
		customColors = Self.load(from: defaults)
		WhiskrKit.shared.setTheme(theme)
	}

	// MARK: - Editing

	func color(for role: ColorRole) -> Color {
		customColors[role.id]?.color ?? role.systemColor
	}

	func isCustom(_ role: ColorRole) -> Bool {
		customColors[role.id] != nil
	}

	func setColor(_ color: Color, for role: ColorRole) {
		customColors[role.id] = HexColor(color)
	}

	func reset(_ role: ColorRole) {
		customColors[role.id] = nil
	}

	func apply(_ preset: ThemePreset) {
		customColors = preset.colors.compactMapValues(HexColor.init)
	}

	/// The preset the current colors are equal to, if any.
	var matchingPreset: ThemePreset? {
		ThemePreset.all.first { $0.colors.compactMapValues(HexColor.init) == customColors }
	}

	// MARK: - Theme

	/// `systemStyle` with each role's color swapped in. Fonts, corner radii and
	/// the selection background stay as in `systemStyle`.
	var theme: WhiskrKitTheme {
		guard !customColors.isEmpty else { return .systemStyle }

		let accent = color(for: .accent)
		let onAccent = color(for: .onAccent)
		let background = color(for: .background)
		let text = color(for: .text)
		let secondaryText = color(for: .secondaryText)
		let selection = color(for: .selection)

		// Like `systemStyle`, sheets and full-screen forms keep the system's own
		// background until one is picked.
		let overlay = customColors[ColorRole.background.id].map {
			WhiskrKitTheme.ContainerTheme.OverlayView(backgroundColor: $0.color)
		}

		return WhiskrKitTheme(
			container: .init(
				sheet: overlay,
				fullScreen: overlay,
				toast: .init(cornerRadius: 8, backgroundColor: background, withShadow: false)
			),
			selectionColor: .init(tintColor: selection, backgroundColor: Color(.tertiarySystemBackground)),
			button: .init(
				primary: .variant(.init(backgroundColor: accent, textColor: onAccent, font: .body.weight(.medium), cornerRadius: 10)),
				secondary: .variant(.init(backgroundColor: .clear, textColor: text, font: .body, cornerRadius: 8))
			),
			title: .init(font: .title2.weight(.bold), color: text),
			subtitle: .init(font: .headline.weight(.semibold), color: secondaryText),
			headline: .init(font: .headline, color: text),
			subheadline: .init(font: .subheadline, color: secondaryText),
			body: .init(font: .body, color: text)
		)
	}

	/// Swift source that builds the same theme as ``theme``. Keep the two in sync.
	var snippet: String {
		guard !customColors.isEmpty else { return "WhiskrKit.shared.setTheme(.systemStyle)" }

		let declarations = ColorRole.all.map { role in
			if let custom = customColors[role.id] {
				"let \(role.id) = \(custom.code) // \(custom.hex)"
			} else {
				"let \(role.id) = \(role.systemCode)"
			}
		}

		let overlayLines = customColors[ColorRole.background.id] == nil ? [] : [
			"        sheet: .init(backgroundColor: background),",
			"        fullScreen: .init(backgroundColor: background),",
		]

		return (declarations + [
			"",
			"let theme = WhiskrKitTheme(",
			"    container: .init(",
		] + overlayLines + [
			"        toast: .init(cornerRadius: 8, backgroundColor: background, withShadow: false)",
			"    ),",
			"    selectionColor: .init(tintColor: selection, backgroundColor: Color(.tertiarySystemBackground)),",
			"    button: .init(",
			"        primary: .variant(.init(backgroundColor: accent, textColor: onAccent, font: .body.weight(.medium), cornerRadius: 10)),",
			"        secondary: .variant(.init(backgroundColor: .clear, textColor: text, font: .body, cornerRadius: 8))",
			"    ),",
			"    title: .init(font: .title2.weight(.bold), color: text),",
			"    subtitle: .init(font: .headline.weight(.semibold), color: secondaryText),",
			"    headline: .init(font: .headline, color: text),",
			"    subheadline: .init(font: .subheadline, color: secondaryText),",
			"    body: .init(font: .body, color: text)",
			")",
			"",
			"WhiskrKit.shared.setTheme(theme)",
		]).joined(separator: "\n")
	}

	// MARK: - Persistence

	/// Stored as JSON `{ "<role id>": "#RRGGBB" }`. Unknown roles and invalid
	/// values are dropped on load.
	private static func load(from defaults: UserDefaults) -> [String: HexColor] {
		guard
			let data = defaults.data(forKey: storageKey),
			let stored = try? JSONDecoder().decode([String: String].self, from: data)
		else { return [:] }

		let knownRoles = Set(ColorRole.all.map(\.id))
		return stored
			.filter { knownRoles.contains($0.key) }
			.compactMapValues(HexColor.init)
	}

	private func save() {
		let stored = customColors.mapValues(\.hex)
		guard let data = try? JSONEncoder().encode(stored) else { return }
		defaults.set(data, forKey: Self.storageKey)
	}
}
