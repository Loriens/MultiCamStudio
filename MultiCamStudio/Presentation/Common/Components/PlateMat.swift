//
//  PlateMat.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct PlateMat<Content: View>: View {
    var inset: CGFloat = 5
    @ViewBuilder
    var content: Content

    var body: some View {
        content
            .padding(inset)
            .background(Theme.raised)
            .overlay(Rectangle().strokeBorder(Theme.matEdge, lineWidth: 1))
    }
}
