//
//  PoweredByBadge.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

/// The "Powered by WhiskrKit" badge, shown below the submit button when the server
/// asks for it (`branding.visible`). Purely decorative: not tappable, no link.
struct PoweredByBadge: View {
    /// What the survey sits on, used to keep the text readable.
    enum Surface {
        case toast
        case sheet
    }

    @Environment(\.WhiskrKitTheme) private var theme
    @Environment(\.self) private var environment
    @Environment(\.isOnPanelSurface) private var isOnPanelSurface
    @ScaledMetric(relativeTo: .caption) private var logoSize: CGFloat = 12

    let surface: Surface

    private var background: Color {
        switch surface {
        case .toast: theme.container?.toast?.backgroundColor ?? Color(.secondarySystemBackground)
        // The floating panel draws glass or material, never the theme's sheet color.
        case .sheet: (isOnPanelSurface ? nil : theme.container?.sheet?.backgroundColor) ?? Color(.systemBackground)
        }
    }

    private var textColor: Color {
        let canvas = Color(.systemBackground)
        return Color(
            BrandingContrast.textColor(
                preferred: theme.subheadline.color.rgba(in: environment),
                background: background.rgba(in: environment),
                canvas: canvas.rgba(in: environment)
            )
        )
    }

    private let label = LocalizedStringResource.poweredByLabel("WhiskrKit")

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image("WhiskrKitLogo", bundle: .module)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                .accessibilityHidden(true)
            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

private extension Color {
    func rgba(in environment: EnvironmentValues) -> BrandingContrast.RGBA {
        let resolved = resolve(in: environment)
        return BrandingContrast.RGBA(
            red: Double(resolved.red),
            green: Double(resolved.green),
            blue: Double(resolved.blue),
            alpha: Double(resolved.opacity)
        )
    }
}

private extension Color {
    init(_ rgba: BrandingContrast.RGBA) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }
}

private struct OnPanelSurfaceKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside the iPad floating panel, whose glass or material surface replaces
    /// the theme's sheet background color.
    var isOnPanelSurface: Bool {
        get { self[OnPanelSurfaceKey.self] }
        set { self[OnPanelSurfaceKey.self] = newValue }
    }
}
