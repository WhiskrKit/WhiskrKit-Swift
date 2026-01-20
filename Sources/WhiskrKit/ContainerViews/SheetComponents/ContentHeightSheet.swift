//
//  ContentHeightSheet.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentHeightSheet: ViewModifier {

    @State private var presentationDetents: Set<PresentationDetent> = [.medium]
    @State private var selectedPresentationDetent: PresentationDetent = .medium

    func body(content: Content) -> some View {
        ScrollView {
            content
                .presentationDetents(presentationDetents, selection: $selectedPresentationDetent)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newValue in
                    presentationDetents.insert(.height(newValue.height))
                    selectedPresentationDetent = .height(newValue.height)
                }
                .transaction { transaction in
                    transaction.addAnimationCompletion(criteria: .removed) {
                        presentationDetents = [selectedPresentationDetent]
                    }
                }
        }
        .scrollDisabled(true)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    func sheetContentHeight() -> some View {
        self.modifier(ContentHeightSheet())
    }
}
