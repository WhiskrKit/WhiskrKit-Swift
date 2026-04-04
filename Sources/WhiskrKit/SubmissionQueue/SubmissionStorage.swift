//
//  SubmissionStorage.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

@MainActor
protocol SubmissionStorage {
    func save(_ submissions: [PendingSubmission])
    func load() -> [PendingSubmission]
    func clear()
}

final class UserDefaultsSubmissionStorage: SubmissionStorage {
    private let userDefaults: UserDefaults
    private let key: String

    init(
        userDefaults: UserDefaults = .standard,
        key: String = SubmissionQueueConfig.storageKey
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func save(_ submissions: [PendingSubmission]) {
        do {
            let data = try JSONEncoder().encode(submissions)
            userDefaults.set(data, forKey: key)
            Logger.wkCache.info("💾 Saved \(submissions.count) submissions to storage")
        } catch {
            Logger.wkCache.warning("❌ Failed to save submissions: \(error)")
        }
    }

    func load() -> [PendingSubmission] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            let submissions = try JSONDecoder().decode([PendingSubmission].self, from: data)
            return submissions
        } catch {
            Logger.wkCache.warning("❌ Failed to load submissions: \(error)")
            return []
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: key)
        Logger.wkCache.info("🗑️ Cleared storage")
    }
}
