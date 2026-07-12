//
//  SheetPlacementModifier.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

private struct WhiskrKitSheetPlacementKey: EnvironmentKey {
    /// `nil` means "unset at this point in the tree", which lets the resolver
    /// distinguish an explicit override from the absence of one and fall back to
    /// the global `defaultSheetPlacement`.
    static let defaultValue: SheetPlacement? = nil
}

extension EnvironmentValues {
    /// The nearest sheet placement override in the view tree, if any.
    ///
    /// Read by `WhiskrKitSurveyModifier` at the trigger's own site. It is *not*
    /// inherited by the panel's own window, so the modifier forwards the resolved
    /// value to the presenter explicitly.
    var whiskrKitSheetPlacement: SheetPlacement? {
        get { self[WhiskrKitSheetPlacementKey.self] }
        set { self[WhiskrKitSheetPlacementKey.self] = newValue }
    }
}

public extension View {

    /// Sets the placement used when a `sheet`-style survey in this subtree
    /// resolves to a floating panel on a wide (regular width) screen.
    ///
    /// This is an ambient hint, modelled on SwiftUI's own `.tint` / `.lineLimit`:
    /// it is consumed only if and when a survey resolves to the sheet style in
    /// regular width, and it is ignored entirely by toast and fullscreen surveys
    /// and in compact width. Because the survey's style is a dashboard decision,
    /// the call site that triggers a survey does not know whether it will be a
    /// sheet — so placement is supplied ambiently rather than as an argument to
    /// ``SwiftUI/View/whiskrKitSurvey(identifier:)``.
    ///
    /// ```swift
    /// SomeDetailView()
    ///     .whiskrKitSheetPlacement(.leading)
    /// ```
    ///
    /// - Parameter placement: The edge a sheet survey should anchor to in regular
    ///   width. Overrides the app-wide `WhiskrKit.configure { $0.defaultSheetPlacement }`.
    func whiskrKitSheetPlacement(_ placement: SheetPlacement) -> some View {
        environment(\.whiskrKitSheetPlacement, placement)
    }
}
