//
//  PressedAppearance.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct PressedAppearance: ViewModifier {
    let isPressed: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.92 : 1)
            .opacity(isPressed ? 0.65 : 1)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}
