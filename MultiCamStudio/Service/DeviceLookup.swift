//
//  DeviceLookup.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreMedia
import Foundation

final class DeviceLookup {
    private let discoverySession: AVCaptureDevice.DiscoverySession

    init() {
        discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .unspecified
        )
    }

    var defaultMicrophone: AVCaptureDevice? { AVCaptureDevice.default(for: .audio) }

    func multiCamPair() -> CameraPair? {
        for set in discoverySession.supportedMultiCamDeviceSets {
            guard let back = set.first(where: { $0.position == .back }) else { continue }
            guard let front = set.first(where: { $0.position == .front }) else { continue }
            return CameraPair(back: back, front: front)
        }
        return nil
    }
}
