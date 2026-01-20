//
//  Logger+Extensions.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import OSLog

extension Logger {
    static let wkUI = Logger(subsystem: "com.WhiskrKit.iosFramework", category: "UI")
    static let wkCore = Logger(subsystem: "com.WhiskrKit.iosFramework", category: "Core")
    static let wkNetworking = Logger(subsystem: "com.WhiskrKit.iosFramework", category: "Networking")
    static let wkCache = Logger(subsystem: "com.WhiskrKit.iosFramework", category: "Cache")
}
