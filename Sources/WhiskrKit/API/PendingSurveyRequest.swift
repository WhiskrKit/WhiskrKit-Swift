//
//  PendingSurveyRequest.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

/// A survey presentation request waiting to be picked up by an active `WhiskrKitSurveyModifier`.
///
/// `fetch` carries only an identifier and requires a template fetch before presentation;
/// `present` carries a template that was already obtained (for example, from an eligibility
/// response) so no second network request is needed.
struct PendingSurveyRequest: Equatable {
	enum Kind {
		case fetch(surveyId: String)
		case present(SurveyTemplate)
	}

	let kind: Kind

	// SurveyTemplate has no stable identity, and every request must re-trigger
	// presentation even when its payload matches the previous one, so equality
	// is per-request rather than structural.
	private let token = UUID()

	static func fetch(surveyId: String) -> Self {
		.init(kind: .fetch(surveyId: surveyId))
	}

	static func present(_ template: SurveyTemplate) -> Self {
		.init(kind: .present(template))
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.token == rhs.token
	}
}
