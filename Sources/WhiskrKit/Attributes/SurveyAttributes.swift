//
//  SurveyAttributes.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import OSLog

/// A value attached to a survey response as an attribute: a string, a number or a bool.
///
/// Literals work directly: `WhiskrKit.shared.setAttribute("plan", "pro")`,
/// `setAttribute("sessions", 3)`, `setAttribute("beta", true)`.
public enum AttributeValue: Codable, Equatable, Sendable,
    ExpressibleByStringLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
    case string(String)
    case number(Double)
    case bool(Bool)

    public init(stringLiteral value: String) { self = .string(value) }
    public init(integerLiteral value: Int) { self = .number(Double(value)) }
    public init(floatLiteral value: Double) { self = .number(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Attribute values must be a string, number or bool"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            guard value.isFinite else {
                throw EncodingError.invalidValue(
                    value,
                    .init(codingPath: encoder.codingPath, debugDescription: "Attribute numbers must be finite")
                )
            }
            // Integral values go out as `3`, not `3.0`.
            if value == value.rounded(), abs(value) < 9_007_199_254_740_992 {
                try container.encode(Int64(value))
            } else {
                try container.encode(value)
            }
        case .bool(let value):
            try container.encode(value)
        }
    }
}

/// Mirrors the limits the server applies, so a payload is never larger than it will accept.
/// The server stays the authority; this only avoids sending data that would be trimmed anyway.
enum SurveyAttributesSanitizer {
    static let maxKeys = 20
    static let maxKeyLength = 64
    static let maxStringLength = 256
    static let maxBytes = 2048

    static func sanitize(_ attributes: [String: AttributeValue]) -> [String: AttributeValue] {
        var result: [String: AttributeValue] = [:]
        for key in attributes.keys.sorted() {
            guard result.count < maxKeys, var value = attributes[key] else { break }

            let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= maxKeyLength, result[trimmed] == nil else { continue }

            switch value {
            case .number(let number) where !number.isFinite:
                continue
            case .string(let string) where string.count > maxStringLength:
                value = .string(String(string.prefix(maxStringLength)))
            default:
                break
            }
            result[trimmed] = value
        }

        guard encodedSize(result) <= maxBytes else { return [:] }
        return result
    }

    static func encodedSize(_ attributes: [String: AttributeValue]) -> Int {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return (try? encoder.encode(attributes).count) ?? Int.max
    }
}

/// Heuristics matching what the server drops as personal data. Used for DEBUG warnings only.
enum PersonalDataHeuristics {
    private static let keyFragments = [
        "email", "mail", "phone", "mobile", "iban", "bsn", "passport", "address", "creditcard"
    ]
    private static let exactKeys: Set<String> = [
        "name", "firstname", "lastname", "fullname", "surname",
        "zip", "zipcode", "postcode", "postalcode"
    ]

    /// Lowercases and keeps letters only, so `E-Mail` and `credit_card` normalise like the server does.
    static func normalized(_ key: String) -> String {
        String(key.lowercased().unicodeScalars.filter { CharacterSet.letters.contains($0) })
    }

    static func isPersonalDataKey(_ key: String) -> Bool {
        let normalized = normalized(key)
        if exactKeys.contains(normalized) { return true }
        return keyFragments.contains { normalized.contains($0) }
    }

    static func looksLikeEmail(_ text: String) -> Bool {
        text.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    static func looksLikeIBAN(_ text: String) -> Bool {
        let compact = text.filter { !$0.isWhitespace }.uppercased()
        return compact.range(of: #"^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$"#, options: .regularExpression) != nil
    }

    /// Logs a warning for suspicious attributes in DEBUG builds. Never logs values and never strips anything.
    static func warnIfNeeded(key: String, value: AttributeValue) {
        #if DEBUG
        if looksLikeEmail(key) {
            Logger.wkCore.warning("⚠️ An attribute key looks like personal data. The server drops personal data, do not send it.")
        } else if isPersonalDataKey(key) {
            Logger.wkCore.warning("⚠️ Attribute '\(key)' looks like personal data. The server drops it, do not send personal data.")
        }
        if case .string(let text) = value, looksLikeEmail(text) || looksLikeIBAN(text) {
            Logger.wkCore.warning("⚠️ The value of attribute '\(key)' looks like an email or IBAN. The server drops personal data, do not send it.")
        }
        #endif
    }
}

extension WhiskrKit {
    /// Sets an attribute that is attached to every survey response submitted afterwards.
    /// Pass `nil` to remove it. Attributes are kept in memory only, so set them again on each launch.
    ///
    /// Only strings, numbers and bools are supported. Do not send personal data such as
    /// emails, phone numbers, names, IBANs or card numbers: the server drops it.
    public func setAttribute(_ key: String, _ value: AttributeValue?) {
        guard let value else {
            surveyAttributes[key] = nil
            return
        }
        PersonalDataHeuristics.warnIfNeeded(key: key, value: value)
        surveyAttributes[key] = value
    }

    /// Merges the given attributes into the current ones. Existing keys are overwritten.
    public func setAttributes(_ attributes: [String: AttributeValue]) {
        for (key, value) in attributes {
            setAttribute(key, value)
        }
    }

    /// Removes one attribute.
    public func removeAttribute(_ key: String) {
        surveyAttributes[key] = nil
    }

    /// Removes all attributes.
    public func clearAttributes() {
        surveyAttributes.removeAll()
    }
}
