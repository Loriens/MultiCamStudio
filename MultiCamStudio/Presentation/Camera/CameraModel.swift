//
//  CameraModel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import Foundation
import ImageIO
import Observation

@MainActor
@Observable
final class CameraModel {
    private(set) var status = CameraStatus.starting
    private(set) var mode = CaptureMode.photo
    private(set) var isRecording = false
    private(set) var isBusy = false
    private(set) var review: CaptureReview?
    private(set) var shutterTapCount = 0
    private(set) var flashCount = 0

    var previewSource: CameraPreviewSource { captureService.previewSource }

    private let captureService: any CameraCaptureService
    private let captureStore: any CaptureStore
    private var eventTask: Task<Void, Never>?
    private var startTask: Task<Void, Never>?
    private var focusTask: Task<Void, Never>?
    private var reviewTask: Task<Void, Never>?

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

    func switchCamera() {
        guard !isRecording, !isBusy else { return }
        isBusy = true
        Task { [weak self] in
            guard let self else { return }
            defer { isBusy = false }
            try? await captureService.selectNextCamera()
        }
    }

    func shutterTapped() {
        shutterTapCount += 1
        switch mode {
        case .photo: capturePhoto()
        case .video: toggleRecording()
        }
    }

    func focus(at point: CGPoint) {
        guard status == .running else { return }
        let devicePoint = previewSource.devicePoint(for: point)
        focusTask?.cancel()
        focusTask = Task { [weak self] in
            guard let self else { return }
            await captureService.focusAndExpose(at: devicePoint)
        }
    }

    private func performStart() async {
        do {
            try await captureService.start(in: mode)
            status = .running
            observeEvents()
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
            do {
                let photo = try await captureService.capturePhoto()
                try await captureStore.savePhotoCapture(back: photo, lens: captureService.activeLens())
                let thumbnail = await Self.makeThumbnail(from: photo.data)
                show(thumbnail.map(CaptureReview.photo) ?? .failure)
            } catch {
                show(.failure)
            }
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
                    let movie = try await captureService.stopRecording()
                    isRecording = false
                    try await captureStore.saveMovieCapture(back: movie, lens: captureService.activeLens())
                    show(.movie(duration: movie.duration))
                } else {
                    try await captureService.startRecording()
                    isRecording = true
                }
            } catch {
                isRecording = false
                show(.failure)
            }
        }
    }

    private func show(_ newReview: CaptureReview) {
        review = newReview
        reviewTask?.cancel()
        reviewTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, let self else { return }
            review = nil
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
                }
            }
        }
    }

    @concurrent
    private nonisolated static func makeThumbnail(from data: Data) async -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 512,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
