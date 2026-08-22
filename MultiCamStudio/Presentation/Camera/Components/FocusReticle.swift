//
//  FocusReticle.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct FocusReticle: View {
    var body: some View {
        Rectangle()
            .strokeBorder(Theme.text.opacity(0.85), lineWidth: 1)
            .frame(width: 68, height: 68)
    }
}
