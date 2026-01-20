//
//  CloseButtonStyle.swift
//  WhiskrKit
//
//  Copyright (c) 2025 Dennis Vermeulen
//  Licensed under the MIT License. See LICENSE file for details.
//

import SwiftUI

struct CloseButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tint(.primary)
                .padding()
                .glassEffect()
        } else {
            content
                .tint(.primary)
                .padding()
                .background(.regularMaterial, in: Circle())
        }
    }
}

extension View {
    func circularClose() -> some View {
        self.modifier(CloseButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray
        Button(action: {
            
        }, label: {
            Image(systemName: "xmark")
                .circularClose()
        })
    }
}
