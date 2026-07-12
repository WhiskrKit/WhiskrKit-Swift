//
//  ToastPlacement.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// Where a `toast`-style survey renders when it is shown on a wide (regular
/// width) screen.
///
/// This is the toast counterpart to ``SheetPlacement`` and is deliberately a
/// *separate* axis: a toast and a sheet are different surfaces, so an integrator
/// can place them independently (and the two vocabularies can diverge later
/// without disturbing each other). Like the sheet's, it is only consulted in
/// regular width — in compact width a toast always renders as the standard
/// full-width bottom toast.
///
/// Set it ambiently, the way you'd set `.tint`:
///
/// ```swift
/// // App-wide default
/// WhiskrKit.configure { $0.defaultToastPlacement = .trailing }
///
/// // Override for a subtree
/// SomeDetailView()
///     .whiskrKitToastPlacement(.leading)
/// ```
public enum ToastPlacement: Sendable, Equatable, CaseIterable {
    /// Regular width: anchored to the bottom-leading corner, width-capped.
    case leading

    /// Regular width: anchored to the bottom-trailing corner, width-capped.
    case trailing

    /// Regular width: centered and width-capped at the bottom.
    ///
    /// The default, because a centered, capped toast is safe in an app the SDK
    /// knows nothing about — it never lands on top of a host's edge navigation,
    /// and a full-width banner on a large iPad looks stretched.
    case bottomCentered
}
