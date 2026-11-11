//
//  StoreReviewRequester.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import StoreKit
import UIKit
import OSLog

/// Asks the system for its review prompt. Behind a protocol so tests never touch StoreKit.
@MainActor
protocol StoreReviewRequester {
    /// Returns whether the system was asked (iOS still decides whether the prompt shows).
    func requestReview() -> Bool
}

/// Uses StoreKit's system review prompt only (App Review Guideline 5.6.1), on the
/// foreground active window scene.
struct SystemStoreReviewRequester: StoreReviewRequester {
    func requestReview() -> Bool {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        guard let scene else {
            Logger.wkCore.info("⭐️ No foreground active window scene; skipping the App Store review request.")
            return false
        }
        AppStore.requestReview(in: scene)
        return true
    }
}

/// Remembers the app version for which a review was last requested.
@MainActor
protocol StoreReviewStorage: AnyObject {
    var lastRequestedAppVersion: String? { get set }
}

final class UserDefaultsStoreReviewStorage: StoreReviewStorage {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let lastRequestedAppVersion = "eu.WhiskrKit.storeReviewRequestedAppVersion"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var lastRequestedAppVersion: String? {
        get { userDefaults.string(forKey: Keys.lastRequestedAppVersion) }
        set { userDefaults.set(newValue, forKey: Keys.lastRequestedAppVersion) }
    }
}
