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

    @State
    private var isPressed = false

    var body: some View {
        let core = RoundedRectangle(cornerRadius: isRecording ? Theme.radiusSmall : 28)
        return ZStack {
            Circle()
                .strokeBorder(Theme.text.opacity(0.24), lineWidth: 1.5)
            core
                .fill(coreColor)
                .padding(isRecording ? 24 : 12)
        }
        .frame(width: 80, height: 80)
        .contentShape(Circle())
        .modifier(PressedAppearance(isPressed: isPressed))
        .opacity(isBusy ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.25), value: isRecording)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    action()
                }
                .onEnded { _ in isPressed = false }
        )
    }

    private var coreColor: Color {
        mode == .video ? Theme.record : Theme.text
    }
}
