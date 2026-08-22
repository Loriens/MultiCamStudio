//
//  CameraPair.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import Foundation

struct CameraPair {
    let back: AVCaptureDevice
    let front: AVCaptureDevice

    func device(for lens: CaptureLens) -> AVCaptureDevice {
        switch lens {
        case .back: back
        case .front: front
        }
    }
}
