//
//  PlaygroundApp.swift
//  WhiskrKitPlayground
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import WhiskrKit

@main
struct PlaygroundApp: App {
	@State private var settings: ThemeSettings

	init() {
		// Mocked surveys need no real API key and never reach the backend.
		WhiskrKit.shared.initialize(apiKey: "playground", withMockedSurveys: true)
		// Created after initialize, because it applies the saved theme right away.
		_settings = State(initialValue: ThemeSettings())
	}

	var body: some Scene {
		WindowGroup {
			PlaygroundView(settings: settings)
				.whiskrKit()
		}
	}
}
