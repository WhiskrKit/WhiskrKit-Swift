//
//  WhiskrKitVersion.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// The SDK's own version, sent with every request so the server can handle
/// compatibility.
///
/// A Swift package has no Info.plist of its own to read the version from: in a
/// statically linked package, `Bundle(for:)` returns the host app's bundle. So the
/// version is written here, once. Bump it with every release; a test fails when it
/// doesn't match the newest version in CHANGELOG.md.
enum WhiskrKitVersion {
    static let current = "0.2.0"
    static let platform = "ios"

    /// The `X-WhiskrKit-SDK` header value, e.g. `ios/0.3.0`. Same format on every platform.
    static var sdkHeader: String { "\(platform)/\(current)" }
    /// The `User-Agent` header value, e.g. `WhiskrKit-ios/0.3.0`.
    static var userAgent: String { "WhiskrKit-\(platform)/\(current)" }
}
