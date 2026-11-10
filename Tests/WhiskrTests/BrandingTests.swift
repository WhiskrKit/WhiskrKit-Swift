//
//  BrandingTests.swift
//  WhiskrKitTests
//
//  Copyright (c) 2026 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation
import Testing
@testable import WhiskrKit

@Suite("Branding decoding")
struct BrandingDecodingTests {

    private func toastJSON(branding: String?) -> String {
        let extra = branding.map { #", "branding": \#($0)"# } ?? ""
        return #"{ "template": "toast", "id": "t1", "title": "Hi", "followUpIdentifier": "f1"\#(extra) }"#
    }

    private func sheetJSON(branding: String?) -> String {
        let extra = branding.map { #", "branding": \#($0)"# } ?? ""
        return #"""
        { "template": "sheet", "id": "s1", "title": "Hi",
          "survey": { "template": "thumbsRating", "id": "q1", "isRequired": false }\#(extra) }
        """#
    }

    private func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Every shape the server could send, and whether the badge must show.
    static let cases: [(label: String, branding: String?, visible: Bool)] = [
        ("visible true", #"{ "visible": true }"#, true),
        ("visible false", #"{ "visible": false }"#, false),
        ("extra fields", #"{ "visible": true, "text": "x" }"#, true),
        ("key missing", nil, false),
        ("null", "null", false),
        ("empty object", "{}", false),
        ("string", #""yes""#, false),
        ("number", "1", false),
        ("bool instead of object", "true", false),
        ("array", "[true]", false),
        ("visible is a string", #"{ "visible": "yes" }"#, false),
        ("visible is a number", #"{ "visible": 1 }"#, false),
        ("visible is null", #"{ "visible": null }"#, false),
    ]

    @Test("ToastTemplate", arguments: cases)
    func toast(_ testCase: (label: String, branding: String?, visible: Bool)) throws {
        let template = try decoder().decode(ToastTemplate.self, from: Data(toastJSON(branding: testCase.branding).utf8))
        #expect(template.branding.isVisible == testCase.visible, "\(testCase.label)")
        #expect(template.id == "t1")
    }

    @Test("SheetTemplate", arguments: cases)
    func sheet(_ testCase: (label: String, branding: String?, visible: Bool)) throws {
        let template = try decoder().decode(SheetTemplate.self, from: Data(sheetJSON(branding: testCase.branding).utf8))
        #expect(template.branding.isVisible == testCase.visible, "\(testCase.label)")
        #expect(template.id == "s1")
    }

    @Test("Fetch-survey response (top-level key) through SurveyTemplate", arguments: cases)
    func surveyTemplate(_ testCase: (label: String, branding: String?, visible: Bool)) throws {
        let toast = try decoder().decode(SurveyTemplate.self, from: Data(toastJSON(branding: testCase.branding).utf8))
        guard case .toast(let toastBase) = toast.presentationBase else { Issue.record("not a toast"); return }
        #expect(toastBase.branding.isVisible == testCase.visible, "\(testCase.label)")

        let sheet = try decoder().decode(SurveyTemplate.self, from: Data(sheetJSON(branding: testCase.branding).utf8))
        guard case .sheet(let sheetBase) = sheet.presentationBase else { Issue.record("not a sheet"); return }
        #expect(sheetBase.branding.isVisible == testCase.visible, "\(testCase.label)")
    }

    @Test("Eligibility response (nested under survey)", arguments: cases)
    func eligibilityResponse(_ testCase: (label: String, branding: String?, visible: Bool)) throws {
        for template in [toastJSON(branding: testCase.branding), sheetJSON(branding: testCase.branding)] {
            let json = #"{ "shouldShow": true, "survey": \#(template) }"#
            let response = try decoder().decode(SurveyEligibilityResponse.self, from: Data(json.utf8))
            #expect(response.shouldShow)
            switch try #require(response.survey).presentationBase {
            case .toast(let base): #expect(base.branding.isVisible == testCase.visible, "\(testCase.label)")
            case .sheet(let base): #expect(base.branding.isVisible == testCase.visible, "\(testCase.label)")
            case .fullScreenForm: Issue.record("unexpected full-screen form")
            }
        }
    }

    @Test("A malformed branding does not change the rest of the survey")
    func malformedKeepsSurvey() throws {
        let json = #"{ "template": "toast", "id": "t1", "title": "Hi", "followUpIdentifier": "f1", "language": "nl", "branding": 42 }"#
        let template = try decoder().decode(ToastTemplate.self, from: Data(json.utf8))
        #expect(template.title == "Hi")
        #expect(template.followUpIdentifier == "f1")
        #expect(template.language == "nl")
        #expect(template.branding.isVisible == false)
    }

    @Test("Memberwise initializers stay source compatible and default to hidden")
    func memberwiseDefault() {
        let toast = ToastTemplate(id: "t", title: nil, description: nil, followUpIdentifier: nil, survey: nil)
        #expect(toast.branding == nil)
        #expect(toast.branding.isVisible == false)
    }
}

@Suite("Branding contrast")
struct BrandingContrastTests {
    typealias RGBA = BrandingContrast.RGBA

    @Test("Black on white is 21:1, identical colors are 1:1")
    func extremes() {
        #expect(abs(BrandingContrast.ratio(.black, .white) - 21) < 0.001)
        #expect(abs(BrandingContrast.ratio(.white, .white) - 1) < 0.001)
    }

    @Test("Matches known WCAG values")
    func knownValue() {
        // #767676 on white is the classic 4.54:1 AA threshold gray.
        let gray = RGBA(red: 0x76 / 255, green: 0x76 / 255, blue: 0x76 / 255)
        let ratio = BrandingContrast.ratio(gray, .white)
        #expect(abs(ratio - 4.54) < 0.01)
    }

    @Test("Keeps a preferred color that already reaches 4.5:1")
    func keepsGoodColor() {
        let dark = RGBA(red: 0.2, green: 0.2, blue: 0.2)
        #expect(BrandingContrast.textColor(preferred: dark, background: .white) == dark)
    }

    @Test("Blends toward black on a light background when contrast is too low")
    func blendsTowardBlack() {
        let lightGray = RGBA(red: 0.7, green: 0.7, blue: 0.7)
        let result = BrandingContrast.textColor(preferred: lightGray, background: .white)
        #expect(BrandingContrast.ratio(result, .white) >= BrandingContrast.minimumRatio)
        // Smallest step: a dark gray, not pure black, and still darker than where it started.
        #expect(result != .black)
        #expect(result.red < 0.7 && result.red > 0.3)
        #expect(result.alpha == 1)
        // One step less would not have been enough.
        let lessBlended = RGBA(red: result.red + 0.007, green: result.green + 0.007, blue: result.blue + 0.007)
        #expect(BrandingContrast.ratio(lessBlended, .white) < BrandingContrast.minimumRatio)
    }

    @Test("Blends toward white on a dark background when contrast is too low")
    func blendsTowardWhite() {
        let navy = RGBA(red: 0.1, green: 0.1, blue: 0.18)
        let dimmed = RGBA(red: 0.25, green: 0.25, blue: 0.4)
        let result = BrandingContrast.textColor(preferred: dimmed, background: navy)
        #expect(BrandingContrast.ratio(result, navy) >= BrandingContrast.minimumRatio)
        #expect(result != .white)
        #expect(result.blue > dimmed.blue && result.blue < 1)
        // Keeps the theme's hue: still bluer than it is red.
        #expect(result.blue > result.red)
    }

    @Test("The result always reaches 4.5:1 or is the best of black and white")
    func resultIsReadable() {
        let backgrounds = [RGBA.white, .black, RGBA(red: 0.5, green: 0.5, blue: 0.5), RGBA(red: 0.9, green: 0.4, blue: 0.1)]
        let texts = [RGBA.white, .black, RGBA(red: 0.5, green: 0.5, blue: 0.5), RGBA(red: 0.2, green: 0.5, blue: 0.9)]
        for background in backgrounds {
            for text in texts {
                let chosen = BrandingContrast.textColor(preferred: text, background: background)
                let ratio = BrandingContrast.ratio(chosen, background)
                let best = max(BrandingContrast.ratio(.black, background), BrandingContrast.ratio(.white, background))
                #expect(ratio >= BrandingContrast.minimumRatio || ratio == best)
            }
        }
    }

    @Test("A translucent text color is judged after blending over the background")
    func translucentText() {
        // 60% black over white is ~#666 (5.7:1): fine. 25% black is ~#BFBFBF (1.8:1): not.
        let strong = RGBA(red: 0, green: 0, blue: 0, alpha: 0.6)
        let faint = RGBA(red: 0, green: 0, blue: 0, alpha: 0.25)
        #expect(BrandingContrast.textColor(preferred: strong, background: .white) == strong)
        let result = BrandingContrast.textColor(preferred: faint, background: .white)
        #expect(BrandingContrast.ratio(result, .white) >= BrandingContrast.minimumRatio)
        #expect(result.alpha == 1)
    }

    @Test("A translucent background is composited over the canvas first")
    func translucentBackground() {
        // 10% black over a black canvas is black, so dark gray text must lighten.
        let background = RGBA(red: 0, green: 0, blue: 0, alpha: 0.1)
        let gray = RGBA(red: 0.3, green: 0.3, blue: 0.3)
        let result = BrandingContrast.textColor(preferred: gray, background: background, canvas: .black)
        #expect(result.red > 0.3)
        #expect(BrandingContrast.ratio(result, .black) >= BrandingContrast.minimumRatio)
    }

    @Test("Blend composites with alpha")
    func blend() {
        let result = BrandingContrast.blend(RGBA(red: 1, green: 0, blue: 0, alpha: 0.5), over: .white)
        #expect(abs(result.red - 1) < 0.001)
        #expect(abs(result.green - 0.5) < 0.001)
        #expect(result.alpha == 1)
    }
}
