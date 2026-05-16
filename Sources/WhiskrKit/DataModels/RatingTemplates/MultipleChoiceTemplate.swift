//
//  MultipleChoiceTemplate.swift
//  WhiskrKit
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct MultipleChoiceTemplate: Decodable {
	let id: String
	let title: String?
	let subtitle: String?
	let isRequired: Bool
	let options: [MultipleChoiceOption]
	let allowsMultiSelection: Bool
}

struct MultipleChoiceOption: Decodable, Hashable {
	let id: String
	let label: String
}
