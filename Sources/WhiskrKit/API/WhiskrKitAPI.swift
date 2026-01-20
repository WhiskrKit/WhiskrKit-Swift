//
//  WhiskrKitAPI.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

public extension View {
    func whiskrKitSurvey(
        identifier: String
    ) -> some View {
        self.modifier(
            WhiskrKitSurveyModifier(
                identifier: identifier
            )
        )
    }
}

struct WhiskrKitSurveyModifier: ViewModifier {
    let identifier: String

    @State private var template: SurveyTemplate?
    @State private var presentsModal: Bool = false
    @State private var presentsToast: Bool = false
    @State private var presentsFullScreen: Bool = false

    func body(content: Content) -> some View {
        content
            .task {
                await fetchSurvey(for: identifier)
            }
            .toast(
                isPresented: $presentsToast,
                template: {
                    if case .toast(let template) = template?.presentationBase {
                        template
                    } else {
                        nil
                    }
                }(),
                openFollowUp: { identifier in
                    Task {
                        await fetchSurvey(for: identifier)
                    }
                }
            )
            .sheet(isPresented: $presentsModal) {
                if case .sheet(let template) = template?.presentationBase {
                    sheetContent(template: template)
                        .sheetStyle()
                }
            }
            .fullScreenCover(isPresented: $presentsFullScreen) {
                if case .fullScreenForm(let template) = template?.presentationBase {
                    fullScreenContent(template: template)
                }
            }.environment(
                \.WhiskrKitTheme,
                 WhiskrKit.shared.theme ?? .systemStyle
            )
    }

    @ViewBuilder
    private func sheetContent(template: SheetTemplate) -> some View {
        SheetContainerView(template: template)
            .sheetContentHeight()
    }

    @ViewBuilder
    private func fullScreenContent(template: FullScreenFormTemplate) -> some View {
        FullScreenContainerView(template: template)
    }

    private func fetchSurvey(for identifier: String) async {
		let fetchedTemplate: SurveyTemplate? = await WhiskrKit.shared.fetchSurveyTemplate(for: identifier)
		guard let fetchedTemplate else { return }
		await MainActor.run {
			self.template = fetchedTemplate
			switch fetchedTemplate.presentationBase {
			case .fullScreenForm:
				presentsFullScreen = true
			case .sheet:
				presentsModal = true
			case .toast:
				presentsToast = true
			}
		}
    }
}

#Preview {
    Text("Welcome to WhiskrKit")
        .title()
}
