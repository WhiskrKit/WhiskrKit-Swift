//
//  SubmissionStorageTests.swift
//  WhiskrKitTests
//
//  Created by WhiskrKit on 16/12/2025.
//

import Testing
import Foundation
@testable import WhiskrKit

@MainActor
@Suite("Submission Storage Tests")
struct SubmissionStorageTests {
    
    // MARK: - Save and Load Tests
    
    @Test("Storage saves and loads submissions correctly")
    func savesAndLoadsCorrectly() {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.storage")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.storage")
        
        let storage = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-submissions"
        )
        
        let submissions = [
            createTestSubmission(surveyId: "test-1"),
            createTestSubmission(surveyId: "test-2")
        ]
        
        storage.save(submissions)
        let loaded = storage.load()
        
        #expect(loaded.count == 2)
        #expect(loaded[0].surveyId == "test-1")
        #expect(loaded[1].surveyId == "test-2")
    }
    
    @Test("Storage returns empty array when no data exists")
    func returnsEmptyArrayWhenNoData() {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.empty")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.empty")
        
        let storage = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "non-existent-key"
        )
        
        let loaded = storage.load()
        #expect(loaded.isEmpty)
    }
    
    @Test("Storage clears data correctly")
    func clearsDataCorrectly() {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.clear")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.clear")
        
        let storage = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-clear"
        )
        
        let submissions = [createTestSubmission(surveyId: "test-1")]
        storage.save(submissions)
        
        #expect(!storage.load().isEmpty)
        
        storage.clear()
        
        #expect(storage.load().isEmpty)
    }
    
    @Test("Storage handles corrupted data gracefully")
    func handlesCorruptedDataGracefully() {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.corrupted")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.corrupted")
        
        let storage = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-corrupted"
        )
        
        // Manually insert corrupted data
        userDefaults.set("corrupted data".data(using: .utf8), forKey: "test-corrupted")
        
        let loaded = storage.load()
        #expect(loaded.isEmpty) // Should return empty array, not crash
    }
    
    @Test("Storage persists data across instances")
    func persistsDataAcrossInstances() {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.persist")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.persist")
        
        let storage1 = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-persist"
        )
        
        let submissions = [createTestSubmission(surveyId: "test-1")]
        storage1.save(submissions)
        
        // Create new storage instance with same UserDefaults
        let storage2 = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-persist"
        )
        
        let loaded = storage2.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].surveyId == "test-1")
    }
    
    @Test("Storage handles large number of submissions")
    func handlesLargeNumberOfSubmissions() {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.large")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.large")
        
        let storage = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-large"
        )
        
        // Create 50 submissions
        var submissions: [PendingSubmission] = []
        for i in 1...50 {
            submissions.append(createTestSubmission(surveyId: "test-\(i)"))
        }
        
        storage.save(submissions)
        let loaded = storage.load()
        
        #expect(loaded.count == 50)
    }
    
    @Test("Storage preserves submission details")
    func preservesSubmissionDetails() throws {
        let userDefaults = UserDefaults(suiteName: "test.whiskrkit.details")!
        userDefaults.removePersistentDomain(forName: "test.whiskrkit.details")
        
        let storage = UserDefaultsSubmissionStorage(
            userDefaults: userDefaults,
            key: "test-details"
        )
        
        var submission = createTestSubmission(surveyId: "test-1")
        submission.incrementRetryCount()
        submission.incrementRetryCount()
        
        storage.save([submission])
        let loaded = storage.load()
        
        let loadedSubmission = try #require(loaded.first)
        #expect(loadedSubmission.id == submission.id)
        #expect(loadedSubmission.idempotencyKey == submission.idempotencyKey)
        #expect(loadedSubmission.surveyId == submission.surveyId)
        #expect(loadedSubmission.retryCount == 2)
        #expect(loadedSubmission.response == submission.response)
    }
}

// MARK: - Helper Functions

private func createTestSubmission(surveyId: String) -> PendingSubmission {
    let response = SurveyResponse(
        results: ["q1": .symbolRating(5)]
    )
    return PendingSubmission(surveyId: surveyId, response: response)
}
