//
//  PulsingDot.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct PulsingDot: View {
    @State
    private var isDim = false

    var body: some View {
        Rectangle()
            .fill(Theme.text)
            .frame(width: 5, height: 5)
            .opacity(isDim ? 0.3 : 1)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isDim)
            .onAppear { isDim = true }
    }
}
