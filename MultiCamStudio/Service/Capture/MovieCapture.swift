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

final class MovieCapture {
    let output = AVCaptureMovieFileOutput()

    private var delegate: MovieRecordingDelegate?

    var isRecording: Bool { output.isRecording }

    var hasPendingRecording: Bool { delegate != nil }

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

    func stop() throws -> TimeInterval {
        guard delegate != nil, output.isRecording else { throw CameraError.notRecording }
        let duration = output.recordedDuration.seconds
        output.stopRecording()
        return duration
    }

    func discard() async {
        guard let recordingDelegate = delegate else { return }
        defer { delegate = nil }
        if output.isRecording {
            output.stopRecording()
        }
        for await _ in recordingDelegate.results { break }
    }

    func finishedMovie(duration: TimeInterval) async throws -> CapturedMovie {
        guard let recordingDelegate = delegate else { throw CameraError.notRecording }
        defer { delegate = nil }
        for await result in recordingDelegate.results {
            let url = try result.get()
            return CapturedMovie(url: url, duration: duration)
        }
        throw CameraError.recordingFailed
    }
}
