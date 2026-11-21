//
//  View+OptionalAccessibility.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

extension View {
    /// Sets the accessibility label only when there is one, instead of an empty label.
    @ViewBuilder
    func accessibilityLabel(ifPresent label: String?) -> some View {
        if let label, !label.isEmpty {
            accessibilityLabel(Text(verbatim: label))
        } else {
            self
        }
    }

    /// Sets the accessibility hint only when there is one, instead of an empty hint.
    @ViewBuilder
    func accessibilityHint(ifPresent hint: String?) -> some View {
        if let hint, !hint.isEmpty {
            accessibilityHint(Text(verbatim: hint))
        } else {
            self
        }
    }
}
