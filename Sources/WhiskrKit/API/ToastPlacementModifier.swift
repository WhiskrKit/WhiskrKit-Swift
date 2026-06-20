//
//  ToastPlacementModifier.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

private struct WhiskrKitToastPlacementKey: EnvironmentKey {
    /// `nil` means "unset here", so the resolver can tell an explicit override
    /// from its absence and fall back to the global `defaultToastPlacement`.
    static let defaultValue: ToastPlacement? = nil
}

extension EnvironmentValues {
    /// The nearest toast placement override in the view tree, if any. Read by
    /// `WhiskrKitSurveyModifier` at the trigger's own site.
    var whiskrKitToastPlacement: ToastPlacement? {
        get { self[WhiskrKitToastPlacementKey.self] }
        set { self[WhiskrKitToastPlacementKey.self] = newValue }
    }
}

public extension View {

    /// Sets the placement used when a `toast`-style survey in this subtree is
    /// shown on a wide (regular width) screen.
    ///
    /// An ambient hint, like SwiftUI's `.tint`: it is consumed only when a survey
    /// resolves to the toast style in regular width, and ignored by sheet and
    /// fullscreen surveys and in compact width. It is a *separate* axis from
    /// ``SwiftUI/View/whiskrKitSheetPlacement(_:)`` — setting one does not affect
    /// the other.
    ///
    /// ```swift
    /// SomeDetailView()
    ///     .whiskrKitToastPlacement(.trailing)
    /// ```
    ///
    /// - Parameter placement: The corner a toast survey should anchor to in
    ///   regular width. Overrides `WhiskrKit.configure { $0.defaultToastPlacement }`.
    func whiskrKitToastPlacement(_ placement: ToastPlacement) -> some View {
        environment(\.whiskrKitToastPlacement, placement)
    }
}
