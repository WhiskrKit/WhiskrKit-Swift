//
//  ContentHeightSheet.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI
import Combine
import UIKit

struct ContentHeightSheet: ViewModifier {
	@State private var contentHeight: CGFloat = 0
	@State private var keyboardHeight: CGFloat = 0
	@State private var detents: Set<PresentationDetent> = [.medium]
	@State private var selected: PresentationDetent = .medium

	private var isEditing: Bool { keyboardHeight > 0 }

	func body(content: Content) -> some View {
		ScrollView {
			content
				.onGeometryChange(for: CGFloat.self) { proxy in
					proxy.size.height
				} action: { newHeight in
					contentHeight = newHeight
					let fitted = PresentationDetent.height(newHeight)
					detents = [fitted]
					selected = fitted
				}
			// Creates the scrollable room past the keyboard. This is what
			// lets the field + button clear it, so the sheet itself never
			// has to grow to .large.
				.padding(.bottom, keyboardHeight)
		}
		.ignoresSafeArea(.keyboard, edges: .bottom)
		.scrollDisabled(!isEditing)
		.scrollDismissesKeyboard(.interactively)
		.frame(maxWidth: .infinity, alignment: .center)
		.presentationDetents(detents, selection: $selected)
		.onReceive(keyboardPublisher) { height in
			keyboardHeight = height
		}
	}

	private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
		Publishers.Merge(
			NotificationCenter.default
				.publisher(for: UIResponder.keyboardWillShowNotification)
				.map { notification -> CGFloat in
					let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
					return frame?.height ?? 0
				},
			NotificationCenter.default
				.publisher(for: UIResponder.keyboardWillHideNotification)
				.map { _ in CGFloat(0) }
		)
		.eraseToAnyPublisher()
	}
}

extension View {
	func sheetContentHeight() -> some View {
		modifier(ContentHeightSheet())
	}
}
