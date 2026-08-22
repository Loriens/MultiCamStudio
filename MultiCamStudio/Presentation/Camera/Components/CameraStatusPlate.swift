//
//  CameraStatusPlate.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CameraStatusPlate: View {
    let status: CameraStatus

    var body: some View {
        ZStack {
            PlaceholderPlate()
            VStack(spacing: Theme.space2) {
                Text(title)
                    .scaledFont(size: 13, weight: .semibold, relativeTo: .callout)
                Text(message)
                    .scaledFont(size: 11, relativeTo: .caption)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.space8)
        }
    }

    private var title: String {
        switch status {
        case .starting: "Starting camera"
        case .unauthorized: "Camera access is off"
        case .unavailable: "No camera here"
        case .interrupted: "Camera paused"
        case .failed, .running: "Camera didn't start"
        }
    }

    private var message: String {
        switch status {
        case .starting: "One moment."
        case .unauthorized: "Turn it on in Settings to see the preview and capture."
        case .unavailable: "The simulator has no camera. Run on a device to capture."
        case .interrupted: "Another app is using the camera."
        case .failed, .running: "Reopen the tab to try again."
        }
    }
}
