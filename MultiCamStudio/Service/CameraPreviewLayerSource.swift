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
    private let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    private let isMirrored: Bool
    private var rotationObserver: RotationObserver?
    private var rotationTask: Task<Void, Never>?
    private var appliedPreviewAngle: CGFloat?

    var previewLayer: CALayer { videoPreviewLayer }

    init(session: AVCaptureMultiCamSession, isMirrored: Bool) {
        self.isMirrored = isMirrored
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.setSessionWithNoConnection(session)
    }

    func devicePoint(for point: CGPoint) -> CGPoint {
        videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
    }

    func connect(port: AVCaptureInput.Port, in session: AVCaptureMultiCamSession) throws {
        let connection = AVCaptureConnection(inputPort: port, videoPreviewLayer: videoPreviewLayer)
        guard session.canAddConnection(connection) else { throw CameraError.addOutputFailed }
        session.addConnection(connection)
        guard isMirrored, connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = true
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
