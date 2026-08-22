//
//  RotationAngles.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics

struct RotationAngles: Sendable {
    let preview: CGFloat
    let capture: CGFloat

    init(coordinator: AVCaptureDevice.RotationCoordinator) {
        preview = coordinator.videoRotationAngleForHorizonLevelPreview
        capture = coordinator.videoRotationAngleForHorizonLevelCapture
    }
}
