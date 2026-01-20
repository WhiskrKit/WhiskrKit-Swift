//
//  SurveyConfiguration.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import Foundation

struct SurveyTemplate: Decodable {
    let presentationBase: PresentationBase
    
    enum PresentationType: String, Decodable {
        case fullScreenForm
        case sheet
        case toast
    }
    
    enum PresentationBase: Decodable {
        case fullScreenForm(base: FullScreenFormTemplate)
        case sheet(base: SheetTemplate)
        case toast(base: ToastTemplate)
    }
    
    public enum CodingKeys: CodingKey {
        case template
    }
    
    init(presentationBase: PresentationBase) {
        self.presentationBase = presentationBase
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let template = try container.decode(PresentationType.self, forKey: .template)
        switch template {
        case .fullScreenForm:
            let surveyBase = try FullScreenFormTemplate(from: decoder)
            self.presentationBase = .fullScreenForm(base: surveyBase)
        case .sheet:
            let surveyBase = try SheetTemplate(from: decoder)
            self.presentationBase = .sheet(base: surveyBase)
        case .toast:
            let surveyBase = try ToastTemplate(from: decoder)
            self.presentationBase = .toast(base: surveyBase)
        }
    }
}
