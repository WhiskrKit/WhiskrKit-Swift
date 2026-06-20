//
//  PlacedEdge.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

/// Internal, shared geometry for WhiskrKit's bottom-anchored placements — the
/// floating panel and the placed toast. Both ``SheetPlacement`` and
/// ``ToastPlacement`` map onto this so the alignment and width-cap logic lives in
/// one place rather than being copied per container.
enum PlacedEdge {
    case leading
    case trailing
    case bottomCentered

    /// Container alignment. Compact width always pins to the bottom (full width),
    /// regardless of the configured placement.
    func alignment(isCompact: Bool) -> Alignment {
        guard !isCompact else { return .bottom }
        switch self {
        case .leading: return .bottomLeading
        case .trailing: return .bottomTrailing
        case .bottomCentered: return .bottom
        }
    }

    /// Width cap. Compact width is unconstrained (spans the full width); the side
    /// placements use `side`, the centered placement uses `centered`.
    func maxWidth(isCompact: Bool, side: CGFloat, centered: CGFloat) -> CGFloat {
        guard !isCompact else { return .infinity }
        switch self {
        case .leading, .trailing: return side
        case .bottomCentered: return centered
        }
    }
}

extension SheetPlacement {
    var edge: PlacedEdge {
        switch self {
        case .leading: .leading
        case .trailing: .trailing
        case .bottomCentered: .bottomCentered
        }
    }
}

extension ToastPlacement {
    var edge: PlacedEdge {
        switch self {
        case .leading: .leading
        case .trailing: .trailing
        case .bottomCentered: .bottomCentered
        }
    }
}
