//
//  SheetPlacement.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// Where a `sheet`-style survey renders when it is shown on a wide (regular
/// width) screen, such as an iPad in full screen or a large Stage Manager window.
///
/// Placement is a *hint*, not a style. The survey's style (toast / sheet /
/// fullscreen) is decided on the dashboard and is unrelated to placement.
/// Placement is read **only** when a survey resolves to the sheet style in
/// regular width — toast and fullscreen ignore it entirely, and in compact width
/// every placement falls back to the standard full-width bottom sheet.
///
/// Set it ambiently, the way you'd set `.tint` or `.lineLimit`:
///
/// ```swift
/// // App-wide default
/// WhiskrKit.configure { $0.defaultSheetPlacement = .trailing }
///
/// // Override for a subtree
/// SomeDetailView()
///     .whiskrKitSheetPlacement(.leading)
/// ```
///
/// The vocabulary (`leading` / `trailing` / `bottomCentered`) is deliberately
/// kept stable so a future Android implementation can map it onto idiomatic
/// Material equivalents (side sheets and bottom sheets).
public enum SheetPlacement: Sendable, Equatable, CaseIterable {
    /// Regular width: a bottom-anchored floating side card on the leading edge.
    /// Opt in only when you know the leading edge of your layout is free.
    case leading

    /// Regular width: a bottom-anchored floating side card on the trailing edge.
    /// Opt in only when you know the trailing edge of your layout is free.
    case trailing

    /// Regular width: a centered, width-capped card anchored to the bottom.
    ///
    /// This is the default because it is the only placement that cannot land on
    /// top of a host app's navigation or toolbar, making it safe in an app the
    /// SDK knows nothing about.
    case bottomCentered
}
