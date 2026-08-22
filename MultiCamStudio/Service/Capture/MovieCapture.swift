//
//  MovieCapture.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import UniformTypeIdentifiers

nonisolated final class MovieCapture {
    let output = AVCaptureMovieFileOutput()

    private var delegate: MovieRecordingDelegate?

    var isRecording: Bool { output.isRecording }

    func setVideoRotationAngle(_ angle: CGFloat) {
        guard let connection = output.connection(with: .video) else { return }
        guard connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    func startRecording() throws -> URL {
        guard !output.isRecording else { throw CameraError.addOutputFailed }
        guard let connection = output.connection(with: .video) else { throw CameraError.addOutputFailed }
        if output.availableVideoCodecTypes.contains(.hevc) {
            output.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
        let url = URL.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(for: .quickTimeMovie)
        let recordingDelegate = MovieRecordingDelegate()
        delegate = recordingDelegate
        output.startRecording(to: url, recordingDelegate: recordingDelegate)
        return url
    }

    func stopRecording() async throws -> CapturedMovie {
        guard let recordingDelegate = delegate, output.isRecording else { throw CameraError.notRecording }
        let duration = output.recordedDuration.seconds
        defer { delegate = nil }
        output.stopRecording()
        for await result in recordingDelegate.results {
            let url = try result.get()
            return CapturedMovie(url: url, duration: duration)
        }
        throw CameraError.recordingFailed
    }
}
