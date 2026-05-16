//
//  MultipleChoiceQuestionView.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct MultipleChoiceQuestionView: View {
	@Environment(SubmissionAlert.self) private var submissionAlert: SubmissionAlert

	@State private var selectedOption: String? = nil
	@State private var selectedOptions: [String] = []

	let template: MultipleChoiceTemplate
	@Binding var surveyResponse: SurveyResponse

	var body: some View {
		RatingContainerView(
			title: template.title,
			subtitle: template.subtitle,
			isRequired: template.isRequired
		) {
			VStack(alignment: .leading, spacing: 16) {
				if template.allowsMultiSelection {
					MultipleChoiceView(
						options: template.options,
						selectedOptions: $selectedOptions
					)
					.onChange(of: selectedOptions) { _, newValue in
						submissionAlert.showAlert[template.id] = (template.isRequired && newValue.isEmpty)
						if newValue.isEmpty {
							surveyResponse.results.removeValue(forKey: template.id)
						} else {
							surveyResponse.results[template.id] = .multipleChoice(newValue)
						}
					}
				} else {
					SingleChoiceView(
						options: template.options,
						selectedOption: $selectedOption
					)
					.onChange(of: selectedOption) { _, newValue in
						submissionAlert.showAlert[template.id] = (template.isRequired && newValue == nil)
						if let newValue {
							surveyResponse.results[template.id] = .multipleChoice([newValue])
						} else {
							surveyResponse.results.removeValue(forKey: template.id)
						}
					}
				}
				if submissionAlert.showAlert[template.id] == true {
					formRequiredMessage
				}
			}
		}
	}

	@ViewBuilder
	var formRequiredMessage: some View {
		Label(.formRequiredMultipleChoiceMessage, systemImage: "exclamationmark.circle.fill")
			.font(.footnote)
			.foregroundStyle(.red)
			.italic()
	}
}

struct SingleChoiceView: View {
	let options: [MultipleChoiceOption]
	@Binding var selectedOption: String?

	var body: some View {
		VStack(spacing: 8) {
			ForEach(options, id: \.id) { option in
				ChoiceView(
					label: option.label,
					isSelected: selectedOption == option.id,
					isMultiSelect: false,
					onTap: {
						selectedOption = selectedOption == option.id ? nil : option.id
						UIAccessibility.post(
							notification: .announcement,
							argument: selectedOption == option.id ? "\(option.label), selected" : "\(option.label), deselected"
						)
					}
				)
			}
		}
	}
}

struct MultipleChoiceView: View {
	let options: [MultipleChoiceOption]
	@Binding var selectedOptions: [String]

	var body: some View {
		VStack(spacing: 8) {
			ForEach(options, id: \.id) { option in
				ChoiceView(
					label: option.label,
					isSelected: selectedOptions.contains(option.id),
					isMultiSelect: true,
					onTap: {
						if selectedOptions.contains(option.id) {
							selectedOptions = selectedOptions.filter { $0 != option.id }
							UIAccessibility.post(notification: .announcement, argument: "\(option.label), unchecked")
						} else {
							selectedOptions.append(option.id)
							UIAccessibility.post(notification: .announcement, argument: "\(option.label), checked")
						}
					}
				)
				.accessibilityValue(selectedOptions.contains(option.id) ? "checked" : "unchecked")
			}
		}
	}
}

struct ChoiceView: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion
	@Environment(\.WhiskrKitTheme) private var WhiskrKitTheme
	let label: String
	let isSelected: Bool
	let isMultiSelect: Bool
	let onTap: () -> Void

	private var tintColor: Color {
		WhiskrKitTheme.selectionColor?.tintColor ?? .primary
	}

	private var backgroundColor: Color {
		WhiskrKitTheme.selectionColor?.backgroundColor ?? Color(.systemBackground)
	}

	var body: some View {
		HStack {
			Image(systemName: icon)
				.renderingMode(.template)
				.foregroundStyle(tintColor)
			Text(label)
				.body()
			Spacer()
		}
		.padding()
		.frame(maxWidth: .infinity)
		.background(backgroundColor)
		.clipShape(RoundedRectangle(cornerRadius: 8))
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(isSelected ? tintColor : .gray, lineWidth: isSelected ? 2 : 0.5)
		)
		.accessibilityElement(children: .ignore)
		.accessibilityLabel(label)
		.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
		.accessibilityHint("Double tap to select")
		.onTapGesture {
			UIImpactFeedbackGenerator(style: .light).impactOccurred()
			onTap()
		}
		.animation(reduceMotion ? .none : .easeInOut(duration: 0.15), value: isSelected)
	}

	private var icon: String {
		switch (isMultiSelect, isSelected) {
		case (true, true):   return "checkmark.square.fill"
		case (true, false):  return "square"
		case (false, true):  return "checkmark.circle.fill"
		case (false, false): return "circle"
		}
	}
}


#Preview {
	@Previewable @State var selectedOption: String? = nil
	@Previewable @State var selectedOptions: [String] = []

	ZStack {
		Color(uiColor: .systemGroupedBackground)
			.ignoresSafeArea()
		ScrollView {
			VStack(spacing: 24) {
				VStack(alignment: .leading, spacing: 8) {
					Text("Single select").font(.headline)
					SingleChoiceView(
						options: [
							MultipleChoiceOption(id: "1", label: "Less than a year"),
							MultipleChoiceOption(id: "2", label: "1–3 years"),
							MultipleChoiceOption(id: "3", label: "3+ years")
						],
						selectedOption: $selectedOption
					)
				}
				VStack(alignment: .leading, spacing: 8) {
					Text("Multi select").font(.headline)
					MultipleChoiceView(
						options: [
							MultipleChoiceOption(id: "1", label: "Surveys"),
							MultipleChoiceOption(id: "2", label: "Analytics"),
							MultipleChoiceOption(id: "3", label: "Feedback forms")
						],
						selectedOptions: $selectedOptions
					)
				}
			}
			.padding()
		}
	}
}
