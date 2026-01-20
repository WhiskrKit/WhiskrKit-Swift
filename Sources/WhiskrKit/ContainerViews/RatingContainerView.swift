//
//  RatingContainerView.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct RatingContainerView<Content: View>: View {
    var title: String?
    var subtitle: String?
    var isRequired: Bool
    
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: hasHeader ? 4 : 0) {
            if hasHeader {
                VStack(alignment: .leading, spacing: 6) {
                    ViewThatFits {
                        HStack(alignment: .center, spacing: 8) {
                            if let title {
                                Text(title)
                                    .headline()
                            }
                            if isRequired {
                                Text(.requiredFieldLabel)
                                    .subheadline()
                                    .italic()
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if let title {
                                Text(title)
                                    .headline()
                            }
                            if isRequired {
                                Text(.requiredFieldLabel)
                                    .subheadline()
                                    .italic()
                            }
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .subheadline()
                    }
                }
            }
            content
                .padding(.vertical, 16)
        }
        
    }
    
    private var hasHeader: Bool {
        title != nil || subtitle != nil
    }
    
}

#Preview("RatingContainerView - short required") {
    RatingContainerView(
        title: "What is the meaning of life?",
        subtitle: "Let me know when you find out.",
        isRequired: true
    ) {
        Text("No way")
    }
}

#Preview("RatingContainerView - long required") {
    RatingContainerView(
        title: "What is the meaning of life? Ask yourself this when you wake up.",
        subtitle: "Let me know when you find out.",
        isRequired: true
    ) {
        Text("No way")
    }
}
