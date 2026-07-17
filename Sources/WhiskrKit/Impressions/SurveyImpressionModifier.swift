//
//  SurveyImpressionModifier.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

extension View {
    /// Records the survey's `seen` state and `shown`/`dismissed` impressions.
    ///
    /// - Parameters:
    ///   - surveyId: The presentation template's `id` — the same id used to submit.
    ///   - didInteract: Set to `true` before teardown to suppress the `dismissed` event.
    func whiskrKitImpressions(surveyId: String, didInteract: Binding<Bool>) -> some View {
        modifier(SurveyImpressionModifier(surveyId: surveyId, didInteract: didInteract))
    }
}

/// Hooks `onAppear`/`onDisappear` rather than the dismiss functions: sheet
/// swipe-to-dismiss and toast drag tear the container down without calling them.
private struct SurveyImpressionModifier: ViewModifier {
    let surveyId: String
    @Binding var didInteract: Bool

    @State private var didReportShown = false
    /// Consumed once at show time and reused for the dismissal.
    @State private var trigger: SurveyImpressionTrigger = .manual

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !didReportShown else { return }
                didReportShown = true
                trigger = WhiskrKit.shared.consumeImpressionTrigger(for: surveyId)
                WhiskrKit.shared.trackSurveySeen(surveyId: surveyId)
                WhiskrKit.shared.recordImpression(surveyId: surveyId, event: .shown, trigger: trigger)
            }
            .onDisappear {
                guard didReportShown, !didInteract else { return }
                WhiskrKit.shared.recordImpression(surveyId: surveyId, event: .dismissed, trigger: trigger)
            }
    }
}
