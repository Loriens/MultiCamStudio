//
//  LoadingIndicator.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct LoadingIndicator: View {
    private static let dotSize: CGFloat = 6
    private static let dimDuration = 0.55
    private static let stagger = 0.18

    @State
    private var isDim = false

    var body: some View {
        HStack(spacing: Theme.space2) {
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(Theme.text)
                    .frame(width: Self.dotSize, height: Self.dotSize)
                    .opacity(isDim ? 0.2 : 1)
                    .animation(
                        .easeInOut(duration: Self.dimDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * Self.stagger),
                        value: isDim
                    )
            }
        }
        .onAppear { isDim = true }
    }
}
