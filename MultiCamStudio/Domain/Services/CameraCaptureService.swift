//
//  CameraCaptureService.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import Foundation

protocol CameraCaptureService: Actor {
    nonisolated var backPreviewSource: CameraPreviewSource { get }
    nonisolated var frontPreviewSource: CameraPreviewSource { get }
    nonisolated var events: AsyncStream<CaptureEvent> { get }

    func start(in mode: CaptureMode) async throws
    func setCaptureMode(_ mode: CaptureMode) async throws
    func focusAndExpose(at devicePoint: CGPoint, lens: CaptureLens) async
    func capturePhoto() async throws -> CapturedPhotoPair
    func startRecording() async throws
    func stopRecording() async throws -> CapturedMoviePair
}
