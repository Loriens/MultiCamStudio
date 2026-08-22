//
//  RotationObserver.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import Foundation

nonisolated final class RotationObserver {
    let angles: AsyncStream<RotationAngles>

    private let coordinator: AVCaptureDevice.RotationCoordinator
    private var tokens: [NSKeyValueObservation] = []

    init(device: AVCaptureDevice, previewLayer: AVCaptureVideoPreviewLayer) {
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        self.coordinator = coordinator

        let (stream, continuation) = AsyncStream.makeStream(
            of: RotationAngles.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        angles = stream
        continuation.yield(RotationAngles(coordinator: coordinator))

        tokens = [
            coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { current, _ in
                continuation.yield(RotationAngles(coordinator: current))
            }
        ]
    }

    deinit {
        tokens.forEach { $0.invalidate() }
    }
}
