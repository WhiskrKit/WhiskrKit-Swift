//
//  BrandingContrast.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// WCAG 2.x contrast maths for the "Powered by WhiskrKit" badge, kept free of
/// SwiftUI so it can be unit tested. The badge's text color comes from the host
/// app's theme, which can be any color on any background, so the badge checks it.
enum BrandingContrast {
    /// WCAG AA for normal-size text.
    static let minimumRatio = 4.5

    /// A color in gamma-encoded sRGB, components 0...1.
    struct RGBA: Equatable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double = 1

        static let black = RGBA(red: 0, green: 0, blue: 0)
        static let white = RGBA(red: 1, green: 1, blue: 1)
    }

    /// Relative luminance of an opaque color (WCAG definition).
    static func luminance(of color: RGBA) -> Double {
        func linear(_ c: Double) -> Double {
            let c = min(max(c, 0), 1)
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(color.red) + 0.7152 * linear(color.green) + 0.0722 * linear(color.blue)
    }

    /// Composites `color` over `backdrop` using its alpha. The result is opaque
    /// when the backdrop is.
    static func blend(_ color: RGBA, over backdrop: RGBA) -> RGBA {
        let a = min(max(color.alpha, 0), 1)
        return RGBA(
            red: color.red * a + backdrop.red * (1 - a),
            green: color.green * a + backdrop.green * (1 - a),
            blue: color.blue * a + backdrop.blue * (1 - a),
            alpha: a + backdrop.alpha * (1 - a)
        )
    }

    /// Contrast ratio between two opaque colors, from 1 to 21.
    static func ratio(_ a: RGBA, _ b: RGBA) -> Double {
        let la = luminance(of: a)
        let lb = luminance(of: b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// The color to draw the badge text in: `preferred` when it reaches 4.5:1 against
    /// the background, otherwise black or white, whichever contrasts more.
    ///
    /// Translucent colors are composited first: the background over `canvas` (what
    /// sits behind the survey), then the text over that background.
    static func textColor(preferred: RGBA, background: RGBA, canvas: RGBA = .white) -> RGBA {
        let backdrop = blend(background, over: blend(canvas, over: .white))
        let text = blend(preferred, over: backdrop)
        if ratio(text, backdrop) >= minimumRatio {
            return preferred
        }
        return ratio(.black, backdrop) >= ratio(.white, backdrop) ? .black : .white
    }
}
