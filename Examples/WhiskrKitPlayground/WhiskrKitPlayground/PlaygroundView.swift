//
//  PlaygroundView.swift
//  WhiskrKitPlayground
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import WhiskrKit

struct PlaygroundView: View {
	let settings: ThemeSettings

	@State private var appearance: Appearance = .system
	@State private var copied = false

	var body: some View {
		NavigationStack {
			Form {
				ForEach(SurveyDescriptor.Group.allCases, id: \.self) { group in
					Section {
						ForEach(SurveyDescriptor.all.filter { $0.group == group }) { survey in
							surveyRow(survey)
						}
					} header: {
						Text(group.rawValue)
					} footer: {
						if group == SurveyDescriptor.Group.allCases.last {
							Text("Surveys are mocked: responses and events are never sent to WhiskrKit.")
						}
					}
				}

				Section("Presets") {
					ForEach(ThemePreset.all) { preset in
						presetRow(preset)
					}
				}

				Section {
					Picker("Preview in", selection: $appearance) {
						ForEach(Appearance.allCases, id: \.self) { Text($0.rawValue) }
					}
					.pickerStyle(.segmented)

					ForEach(ColorRole.all) { role in
						colorRow(role)
					}
				} header: {
					Text("Colors")
				} footer: {
					Text("A picked color is fixed: it looks the same in light and dark mode. Reset a color to go back to its adaptive system color.")
				}

				Section("Code") {
					ScrollView(.horizontal) {
						Text(settings.snippet)
							.font(.system(.caption2, design: .monospaced))
							.textSelection(.enabled)
							.padding(.vertical, 4)
					}

					Button {
						UIPasteboard.general.string = settings.snippet
						copied = true
					} label: {
						Label(copied ? "Copied" : "Copy code", systemImage: copied ? "checkmark" : "doc.on.doc")
					}
				}
			}
			.navigationTitle("WhiskrKit Playground")
		}
		.preferredColorScheme(appearance.colorScheme)
		.task(id: copied) {
			guard copied else { return }
			try? await Task.sleep(for: .seconds(2))
			copied = false
		}
	}

	private func surveyRow(_ survey: SurveyDescriptor) -> some View {
		Button {
			WhiskrKit.shared.present(surveyId: survey.id)
		} label: {
			Label {
				VStack(alignment: .leading, spacing: 2) {
					Text(survey.name)
						.foregroundStyle(.primary)
					Text(survey.summary)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			} icon: {
				Image(systemName: survey.systemImage)
			}
		}
	}

	private func presetRow(_ preset: ThemePreset) -> some View {
		Button {
			settings.apply(preset)
		} label: {
			HStack {
				Text(preset.name)
					.foregroundStyle(.primary)
				Spacer()
				HStack(spacing: -4) {
					ForEach(ColorRole.all) { role in
						Circle()
							.fill(preset.colors[role.id].flatMap(HexColor.init)?.color ?? role.systemColor)
							.overlay(Circle().strokeBorder(.separator))
							.frame(width: 18, height: 18)
					}
				}
				Image(systemName: "checkmark")
					.opacity(settings.matchingPreset?.id == preset.id ? 1 : 0)
					.accessibilityHidden(settings.matchingPreset?.id != preset.id)
			}
		}
		.accessibilityAddTraits(settings.matchingPreset?.id == preset.id ? .isSelected : [])
	}

	private func colorRow(_ role: ColorRole) -> some View {
		HStack {
			ColorPicker(
				selection: Binding(
					get: { settings.color(for: role) },
					set: { settings.setColor($0, for: role) }
				),
				supportsOpacity: false
			) {
				VStack(alignment: .leading, spacing: 2) {
					Text(role.name)
					Text(role.summary)
						.font(.caption)
						.foregroundStyle(.secondary)
					Text(settings.customColors[role.id]?.hex ?? "System")
						.font(.caption.monospaced())
						.foregroundStyle(.secondary)
				}
			}

			if settings.isCustom(role) {
				Button {
					settings.reset(role)
				} label: {
					Image(systemName: "arrow.uturn.backward.circle")
				}
				.buttonStyle(.borderless)
				.accessibilityLabel("Reset \(role.name) to system color")
			}
		}
	}
}

/// Forces light or dark mode so a theme can be checked in both.
enum Appearance: String, CaseIterable {
	case system = "System"
	case light = "Light"
	case dark = "Dark"

	var colorScheme: ColorScheme? {
		switch self {
		case .system: nil
		case .light: .light
		case .dark: .dark
		}
	}
}

#Preview {
	PlaygroundView(settings: ThemeSettings(defaults: UserDefaults(suiteName: "preview")!))
		.whiskrKit()
}
