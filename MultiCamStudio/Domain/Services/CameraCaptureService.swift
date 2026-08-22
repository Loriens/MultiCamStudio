//
//  CameraCaptureService.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import Foundation

nonisolated protocol CameraCaptureService: Actor {
    nonisolated var previewSource: CameraPreviewSource { get }
    nonisolated var events: AsyncStream<CaptureEvent> { get }

    func start(in mode: CaptureMode) async throws
    func setCaptureMode(_ mode: CaptureMode) async throws
    func selectNextCamera() async throws
    func activeLens() async -> CaptureLens
    func focusAndExpose(at devicePoint: CGPoint) async
    func capturePhoto() async throws -> CapturedPhoto
    func startRecording() async throws
    func stopRecording() async throws -> CapturedMovie
}
