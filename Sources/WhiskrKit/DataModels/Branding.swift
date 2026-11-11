//
//  Branding.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// Branding the server asks the SDK to render in a survey. The server decides
/// (from the account's entitlements); the SDK only renders what it is told.
///
/// Decoding never fails: anything other than `{ "visible": true }` (a missing key,
/// `null`, a wrong type, a malformed `visible`) yields `visible == false`, so a
/// malformed `branding` can neither break the survey nor show the badge.
struct Branding: Decodable, Equatable {
    /// Whether the "Powered by WhiskrKit" badge is shown.
    var visible: Bool

    init(visible: Bool = false) {
        self.visible = visible
    }

    private enum CodingKeys: String, CodingKey {
        case visible
    }

    init(from decoder: any Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        self.visible = (try? container?.decode(Bool.self, forKey: .visible)) ?? false
    }
}

extension Optional where Wrapped == Branding {
    /// True only when the server explicitly asked for the badge.
    var isVisible: Bool { self?.visible ?? false }
}
