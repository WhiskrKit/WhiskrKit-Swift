//
//  SDKVersionTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import Testing
@testable import WhiskrKit

@Suite("SDK version")
struct SDKVersionTests {

    /// Releases are git tags named after the newest CHANGELOG.md version, so the
    /// constant must match it. Fails when a release bumps one but not the other.
    @Test("The version constant matches the newest version in CHANGELOG.md")
    func versionMatchesChangelog() throws {
        let changelogURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../CHANGELOG.md")
            .standardized
        let changelog = try String(contentsOf: changelogURL, encoding: .utf8)
        let versions = changelog
            .split(separator: "\n")
            .compactMap { $0.wholeMatch(of: /## (\d+\.\d+\.\d+)( .*)?/)?.output.1 }
        let newest = try #require(versions.first, "CHANGELOG.md has no version heading")
        #expect(WhiskrKitVersion.current == String(newest))
    }

    @Test("The version is a plain semantic version")
    func versionFormat() {
        #expect(WhiskrKitVersion.current.wholeMatch(of: /\d+\.\d+\.\d+/) != nil)
    }

    @MainActor
    @Test("Requests carry the SDK platform and version")
    func requestHeaders() {
        let service = NetworkService(baseURL: URL(string: "https://example.invalid")!)
        var request = URLRequest(url: URL(string: "https://example.invalid/api")!)
        service.addCommonHeaders(to: &request, apiKey: "key")

        #expect(request.value(forHTTPHeaderField: "X-WhiskrKit-SDK") == "ios/\(WhiskrKitVersion.current)")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "WhiskrKit-ios/\(WhiskrKitVersion.current)")
    }
}
