//
//  DeviceLookup.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation

nonisolated final class DeviceLookup {
    private let backCameraDiscoverySession: AVCaptureDevice.DiscoverySession
    private let frontCameraDiscoverySession: AVCaptureDevice.DiscoverySession

    init() {
        backCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        frontCameraDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )
    }

    var cameras: [AVCaptureDevice] {
        [backCameraDiscoverySession.devices.first, frontCameraDiscoverySession.devices.first]
            .compactMap { $0 }
    }

    var defaultCamera: AVCaptureDevice? { cameras.first }

    var defaultMicrophone: AVCaptureDevice? { AVCaptureDevice.default(for: .audio) }
}
