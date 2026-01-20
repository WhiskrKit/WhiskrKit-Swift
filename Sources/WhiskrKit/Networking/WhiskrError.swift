//
//  WhiskrKitError.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

enum WhiskrKitError: Error {
    case notInitialized
    case unauthorized
    case forbidden
    case notFound
    case badRequest
    case rateLimited
    case serverError
    case networkError(Error)
    case invalidResponse
    case decodingFailed(Error)
    case submissionFailed
    case httpError(statusCode: Int)
}
