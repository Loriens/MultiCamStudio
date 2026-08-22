//
//  PhotoCaptureDelegate.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import Foundation

nonisolated final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: CheckedContinuation<CapturedPhoto, Error>
    private let fileExtension: String
    private var photoData: Data?

    init(continuation: CheckedContinuation<CapturedPhoto, Error>, fileExtension: String) {
        self.continuation = continuation
        self.fileExtension = fileExtension
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        photoData = photo.fileDataRepresentation()
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error {
            continuation.resume(throwing: error)
            return
        }
        guard let photoData else {
            continuation.resume(throwing: CameraError.noPhotoData)
            return
        }
        continuation.resume(returning: CapturedPhoto(data: photoData, fileExtension: fileExtension))
    }
}
