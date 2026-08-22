//
//  PhotoCapture.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import Foundation

final class PhotoCapture {
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

    func capturePhoto() async throws -> CapturedPhoto {
        let usesHEVC = output.availablePhotoCodecTypes.contains(.hevc)
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate(
                continuation: continuation,
                fileExtension: usesHEVC ? "heic" : "jpg"
            )
            activeDelegate = delegate
            output.capturePhoto(with: makeSettings(usesHEVC: usesHEVC), delegate: delegate)
        }
    }

    private func makeSettings(usesHEVC: Bool) -> AVCapturePhotoSettings {
        usesHEVC
            ? AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            : AVCapturePhotoSettings()
    }
}
