//
//  CameraPreviewLayerSource.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import Foundation
import QuartzCore

@MainActor
final class CameraPreviewLayerSource: CameraPreviewSource {
    private let videoPreviewLayer: AVCaptureVideoPreviewLayer
    private var rotationObserver: RotationObserver?
    private var rotationTask: Task<Void, Never>?
    private var appliedPreviewAngle: CGFloat?

    var previewLayer: CALayer { videoPreviewLayer }

    init(session: AVCaptureSession) {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    func devicePoint(for point: CGPoint) -> CGPoint {
        videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
    }

    func trackRotation(for device: AVCaptureDevice) -> AsyncStream<CGFloat> {
        let observer = RotationObserver(device: device, previewLayer: videoPreviewLayer)
        rotationObserver = observer

        let (stream, continuation) = AsyncStream.makeStream(
            of: CGFloat.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        rotationTask?.cancel()
        rotationTask = Task { [weak self] in
            for await angles in observer.angles {
                guard let self else { break }
                apply(angles.preview)
                continuation.yield(angles.capture)
            }
            continuation.finish()
        }
        return stream
    }

    private func apply(_ previewAngle: CGFloat) {
        guard previewAngle != appliedPreviewAngle else { return }
        guard let connection = videoPreviewLayer.connection else { return }
        guard connection.isVideoRotationAngleSupported(previewAngle) else { return }
        connection.videoRotationAngle = previewAngle
        appliedPreviewAngle = previewAngle
    }
}
