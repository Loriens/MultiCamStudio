//
//  PhotoCapture.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import Foundation

nonisolated final class PhotoCapture {
    let output = AVCapturePhotoOutput()

    private var activeDelegate: PhotoCaptureDelegate?

    func prepare() {
        output.isAutoDeferredPhotoDeliveryEnabled = false
    }

    func setVideoRotationAngle(_ angle: CGFloat) {
        guard let connection = output.connection(with: .video) else { return }
        guard connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            activeDelegate = delegate
            output.capturePhoto(with: makeSettings(), delegate: delegate)
        }
    }

    private func makeSettings() -> AVCapturePhotoSettings {
        let settings =
            output.availablePhotoCodecTypes.contains(.hevc)
            ? AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            : AVCapturePhotoSettings()
        return settings
    }
}
