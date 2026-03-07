//
//  EligibilityStorage.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

protocol EligibilityStorage: AnyObject {
    var deviceId: String { get }
    var sessionCount: Int { get }
    var installDate: Date { get }
    var lastSurveyDate: Date? { get set }
    var completedSurveys: [String: Date] { get set }
    func nextCheckAfter(for surveyId: String) -> Date?
    func setNextCheckAfter(_ date: Date?, for surveyId: String)
    func removeCompletedSurvey(_ surveyId: String)
    func incrementSessionCount()
    /// Sets deviceId and installDate on first call; subsequent calls are no-ops.
    func initializeIfNeeded()
}

final class UserDefaultsEligibilityStorage: EligibilityStorage {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let deviceId = "eu.WhiskrKit.deviceId"
        static let sessionCount = "eu.WhiskrKit.sessionCount"
        static let installDate = "eu.WhiskrKit.installDate"
        static let lastSurveyDate = "eu.WhiskrKit.lastSurveyDate"
        static let completedSurveys = "eu.WhiskrKit.completedSurveys"
        static func nextCheckAfter(for surveyId: String) -> String {
            "eu.WhiskrKit.nextCheckAfter.\(surveyId)"
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var deviceId: String {
        userDefaults.string(forKey: Keys.deviceId) ?? ""
    }

    var sessionCount: Int {
        userDefaults.integer(forKey: Keys.sessionCount)
    }

    var installDate: Date {
        userDefaults.object(forKey: Keys.installDate) as? Date ?? Date()
    }

    var lastSurveyDate: Date? {
        get { userDefaults.object(forKey: Keys.lastSurveyDate) as? Date }
        set { userDefaults.set(newValue, forKey: Keys.lastSurveyDate) }
    }

    var completedSurveys: [String: Date] {
        get {
            guard let data = userDefaults.data(forKey: Keys.completedSurveys) else { return [:] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode([String: Date].self, from: data)) ?? [:]
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(newValue) {
                userDefaults.set(data, forKey: Keys.completedSurveys)
            }
        }
    }

    func removeCompletedSurvey(_ surveyId: String) {
        var completed = completedSurveys
        completed.removeValue(forKey: surveyId)
        completedSurveys = completed
    }

    func nextCheckAfter(for surveyId: String) -> Date? {
        userDefaults.object(forKey: Keys.nextCheckAfter(for: surveyId)) as? Date
    }

    func setNextCheckAfter(_ date: Date?, for surveyId: String) {
        userDefaults.set(date, forKey: Keys.nextCheckAfter(for: surveyId))
    }

    func incrementSessionCount() {
        let current = userDefaults.integer(forKey: Keys.sessionCount)
        userDefaults.set(current + 1, forKey: Keys.sessionCount)
        Logger.wkCore.info("📊 Session count incremented to \(current + 1)")
    }

    func initializeIfNeeded() {
        if userDefaults.string(forKey: Keys.deviceId) == nil {
            let newId = UUID().uuidString
            userDefaults.set(newId, forKey: Keys.deviceId)
            Logger.wkCore.info("🆔 Generated new device ID: \(newId)")
        }
        if userDefaults.object(forKey: Keys.installDate) == nil {
            userDefaults.set(Date(), forKey: Keys.installDate)
            Logger.wkCore.info("📅 Install date set for the first time")
        }
    }
}
