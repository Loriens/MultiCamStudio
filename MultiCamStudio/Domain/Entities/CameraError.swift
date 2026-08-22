//
//  CameraError.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

enum CameraError: Error, Sendable {
    case cameraUnavailable
    case multiCamUnsupported
    case notAuthorized
    case addInputFailed
    case addOutputFailed
    case noPhotoData
    case notRecording
    case recordingFailed
}
