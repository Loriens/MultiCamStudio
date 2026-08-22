//
//  CameraChannel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import Foundation

final class CameraChannel {
    let lens: CaptureLens
    let previewSource: CameraPreviewLayerSource
    let photoCapture = PhotoCapture()
    let movieCapture = MovieCapture()

    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var videoPort: AVCaptureInput.Port?
    var audioPort: AVCaptureInput.Port?
    var rotationTask: Task<Void, Never>?
    var captureRotationAngle: CGFloat = 90

    init(lens: CaptureLens, previewSource: CameraPreviewLayerSource) {
        self.lens = lens
        self.previewSource = previewSource
    }
}
