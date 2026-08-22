//
//  ShutterButton.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct ShutterButton: View {
    let mode: CaptureMode
    let isRecording: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        let core = RoundedRectangle(cornerRadius: isRecording ? Theme.radiusSmall : 28)
        return Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(Theme.text.opacity(0.24), lineWidth: 1.5)
                core
                    .fill(coreColor)
                    .padding(isRecording ? 24 : 12)
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(PressableButtonStyle())
        .opacity(isBusy ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.25), value: isRecording)
    }

    private var coreColor: Color {
        mode == .video ? Theme.record : Theme.text
    }
}
