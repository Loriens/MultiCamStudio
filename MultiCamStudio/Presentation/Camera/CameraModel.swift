//
//  CameraModel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class CameraModel {
    private(set) var status = CameraStatus.starting
    private(set) var mode = CaptureMode.photo
    private(set) var isRecording = false
    private(set) var isBusy = false
    private(set) var shutterTapCount = 0
    private(set) var flashCount = 0

    private(set) var isFrontLeading = false

    var backPreviewSource: CameraPreviewSource { captureService.backPreviewSource }

    var frontPreviewSource: CameraPreviewSource { captureService.frontPreviewSource }

    var leadingLens: CaptureLens { isFrontLeading ? .front : .back }

    private let captureService: any CameraCaptureService
    private let captureStore: any CaptureStore
    private var eventTask: Task<Void, Never>?
    private var startTask: Task<Void, Never>?
    private var focusTask: Task<Void, Never>?

    init(captureService: any CameraCaptureService, captureStore: any CaptureStore) {
        self.captureService = captureService
        self.captureStore = captureStore
    }

    func start() async {
        if let startTask {
            await startTask.value
            return
        }
        guard status != .running else { return }
        let task = Task { [weak self] in
            guard let self else { return }
            await performStart()
        }
        startTask = task
        await task.value
        startTask = nil
    }

    func selectMode(_ newMode: CaptureMode) {
        guard !isRecording, !isBusy, newMode != mode else { return }
        let previousMode = mode
        mode = newMode
        isBusy = true
        Task { [weak self] in
            guard let self else { return }
            defer { isBusy = false }
            do {
                try await captureService.setCaptureMode(newMode)
            } catch {
                mode = previousMode
            }
        }
    }

    func swapLeadingLens() {
        isFrontLeading.toggle()
    }

    func shutterTapped() {
        shutterTapCount += 1
        switch mode {
        case .photo: capturePhoto()
        case .video: toggleRecording()
        }
    }

    func focus(at point: CGPoint, lens: CaptureLens) {
        guard status == .running else { return }
        let source = lens == .back ? backPreviewSource : frontPreviewSource
        let devicePoint = source.devicePoint(for: point)
        focusTask?.cancel()
        focusTask = Task { [weak self] in
            guard let self else { return }
            await captureService.focusAndExpose(at: devicePoint, lens: lens)
        }
    }

    private func performStart() async {
        do {
            try await captureService.start(in: mode)
            status = .running
            observeEvents()
        } catch CameraError.multiCamUnsupported {
            status = .multiCamUnsupported
        } catch CameraError.cameraUnavailable {
            status = .unavailable
        } catch CameraError.notAuthorized {
            status = .unauthorized
        } catch {
            status = .failed
        }
    }

    private func capturePhoto() {
        guard !isBusy else { return }
        isBusy = true
        flashCount += 1
        Task { [weak self] in
            guard let self else { return }
            defer { isBusy = false }
            guard let photos = try? await captureService.capturePhoto() else { return }
            try? await captureStore.savePhotoCapture(photos)
        }
    }

    private func toggleRecording() {
        guard !isBusy else { return }
        isBusy = true
        Task { [weak self] in
            guard let self else { return }
            defer { isBusy = false }
            do {
                if isRecording {
                    let movies = try await captureService.stopRecording()
                    isRecording = false
                    try await captureStore.saveMovieCapture(movies)
                } else {
                    try await captureService.startRecording()
                    isRecording = true
                }
            } catch {
                isRecording = false
            }
        }
    }

    private func observeEvents() {
        eventTask?.cancel()
        eventTask = Task { [weak self] in
            guard let self else { return }
            for await event in captureService.events {
                switch event {
                case .interrupted: status = .interrupted
                case .resumed: status = .running
                case .recordingDiscarded: isRecording = false
                case .failed: status = .failed
                }
            }
        }
    }
}
