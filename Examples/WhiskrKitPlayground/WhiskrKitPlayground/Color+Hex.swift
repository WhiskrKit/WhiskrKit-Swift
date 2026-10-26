//
//  Color+Hex.swift
//  WhiskrKitPlayground
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

/// An opaque sRGB color stored as `#RRGGBB`, the persisted form of a picked color.
struct HexColor: Equatable {
	let red: Double
	let green: Double
	let blue: Double

	init?(_ hex: String) {
		var value = hex.trimmingCharacters(in: .whitespaces)
		if value.hasPrefix("#") { value.removeFirst() }
		guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }
		red = Double((rgb >> 16) & 0xFF) / 255
		green = Double((rgb >> 8) & 0xFF) / 255
		blue = Double(rgb & 0xFF) / 255
	}

	/// Resolves `color` in a light environment and drops its opacity.
	init(_ color: Color) {
		let resolved = color.resolve(in: EnvironmentValues())
		// Rounding to 8 bits up front keeps a round trip through `hex` stable.
		func channel(_ value: Float) -> Double { (Double(min(max(value, 0), 1)) * 255).rounded() / 255 }
		red = channel(resolved.red)
		green = channel(resolved.green)
		blue = channel(resolved.blue)
	}

	var hex: String {
		func byte(_ value: Double) -> Int { Int((value * 255).rounded()) }
		return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
	}

	var color: Color {
		Color(.sRGB, red: red, green: green, blue: blue)
	}

	/// Swift source that recreates this color without helper code.
	var code: String {
		String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", red, green, blue)
	}
}
