//
//  CameraError.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

nonisolated enum CameraError: Error, Sendable {
    case cameraUnavailable
    case notAuthorized
    case addInputFailed
    case addOutputFailed
    case deviceChangeFailed
    case noPhotoData
    case notRecording
    case recordingFailed
}
