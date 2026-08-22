//
//  CaptureService.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import Foundation

actor CaptureService: CameraCaptureService {
    nonisolated let events: AsyncStream<CaptureEvent>

    nonisolated var previewSource: CameraPreviewSource { previewLayerSource }

    private nonisolated(unsafe) let captureSession: AVCaptureSession
    private let previewLayerSource: CameraPreviewLayerSource
    private nonisolated let eventContinuation: AsyncStream<CaptureEvent>.Continuation
    private let photoCapture = PhotoCapture()
    private let movieCapture = MovieCapture()
    private let deviceLookup = DeviceLookup()

    private var activeVideoInput: AVCaptureDeviceInput?
    private var activeAudioInput: AVCaptureDeviceInput?
    private var rotationTask: Task<Void, Never>?
    private var notificationTask: Task<Void, Never>?
    private var captureRotationAngle: CGFloat = 90
    private var captureMode = CaptureMode.photo
    private var lastMovieURL: URL?
    private var isSetUp = false

    @MainActor
    init() {
        let session = AVCaptureSession()
        captureSession = session
        previewLayerSource = CameraPreviewLayerSource(session: session)
        let (stream, continuation) = AsyncStream.makeStream(
            of: CaptureEvent.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        events = stream
        eventContinuation = continuation
    }

    func start(in mode: CaptureMode) async throws {
        guard !captureSession.isRunning else { return }
        guard let camera = deviceLookup.defaultCamera else { throw CameraError.cameraUnavailable }
        guard await isAuthorizedForVideo else { throw CameraError.notAuthorized }

        try setUpSession(with: camera)
        observeSessionNotifications()
        await startRotationTracking(for: camera)
        captureSession.startRunning()
        Task(priority: .background) { purgeOrphanedMovies() }

        if mode != captureMode {
            try await setCaptureMode(mode)
        }
    }

    func setCaptureMode(_ mode: CaptureMode) async throws {
        guard mode != captureMode else { return }
        if mode == .video {
            await addAudioInputIfPermitted()
        }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        switch mode {
        case .photo:
            captureSession.sessionPreset = .photo
            captureSession.removeOutput(movieCapture.output)
        case .video:
            captureSession.sessionPreset = .high
            try addOutput(movieCapture.output)
            movieCapture.setVideoRotationAngle(captureRotationAngle)
        }
        captureMode = mode
    }

    func selectNextCamera() async throws {
        let cameras = deviceLookup.cameras
        guard cameras.count > 1, let currentInput = activeVideoInput else {
            throw CameraError.deviceChangeFailed
        }
        let index = cameras.firstIndex(of: currentInput.device) ?? 0
        let next = cameras[(index + 1) % cameras.count]

        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        do {
            activeVideoInput = try addInput(for: next)
        } catch {
            captureSession.addInput(currentInput)
            captureSession.commitConfiguration()
            throw CameraError.deviceChangeFailed
        }
        captureSession.commitConfiguration()

        await startRotationTracking(for: next)
    }

    func focusAndExpose(at devicePoint: CGPoint) {
        guard let device = activeVideoInput?.device else { return }
        try? lockAndFocus(device, at: devicePoint)
    }

    func activeLens() -> CaptureLens {
        activeVideoInput?.device.position == .front ? .front : .back
    }

    func capturePhoto() async throws -> CapturedPhoto {
        try await photoCapture.capturePhoto()
    }

    func startRecording() async throws {
        let url = try movieCapture.startRecording()
        replaceLastMovie(with: url)
    }

    func stopRecording() async throws -> CapturedMovie {
        try await movieCapture.stopRecording()
    }

    private func setUpSession(with camera: AVCaptureDevice) throws {
        guard !isSetUp else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .photo
        activeVideoInput = try addInput(for: camera)
        try addOutput(photoCapture.output)
        photoCapture.prepare()
        captureMode = .photo
        isSetUp = true
    }

    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else { throw CameraError.addInputFailed }
        captureSession.addInput(input)
        return input
    }

    private func addOutput(_ output: AVCaptureOutput) throws {
        guard captureSession.canAddOutput(output) else { throw CameraError.addOutputFailed }
        captureSession.addOutput(output)
    }

    private func addAudioInputIfPermitted() async {
        guard activeAudioInput == nil else { return }
        guard await isAuthorizedForAudio else { return }
        guard let microphone = deviceLookup.defaultMicrophone else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        activeAudioInput = try? addInput(for: microphone)
    }

    private func startRotationTracking(for device: AVCaptureDevice) async {
        rotationTask?.cancel()
        let angles = await previewLayerSource.trackRotation(for: device)
        rotationTask = Task {
            for await angle in angles {
                applyCaptureRotation(angle)
            }
        }
    }

    private func applyCaptureRotation(_ angle: CGFloat) {
        captureRotationAngle = angle
        photoCapture.setVideoRotationAngle(angle)
        movieCapture.setVideoRotationAngle(angle)
    }

    private func lockAndFocus(_ device: AVCaptureDevice, at devicePoint: CGPoint) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
            device.focusPointOfInterest = devicePoint
            device.focusMode = .autoFocus
        }
        if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
            device.exposurePointOfInterest = devicePoint
            device.exposureMode = .autoExpose
        }
    }

    private func replaceLastMovie(with url: URL?) {
        if let previous = lastMovieURL, previous != url {
            try? FileManager.default.removeItem(at: previous)
        }
        lastMovieURL = url
    }

    private func purgeOrphanedMovies() {
        guard !movieCapture.isRecording else { return }
        let fileManager = FileManager.default
        let contents = try? fileManager.contentsOfDirectory(
            at: .temporaryDirectory,
            includingPropertiesForKeys: nil
        )
        for url in contents ?? [] where url.pathExtension == "mov" && url != lastMovieURL {
            try? fileManager.removeItem(at: url)
        }
    }

    private func observeSessionNotifications() {
        notificationTask?.cancel()
        notificationTask = Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.observeInterruptions() }
                group.addTask { await self.observeInterruptionEnd() }
                group.addTask { await self.observeRuntimeErrors() }
            }
        }
    }

    private func observeInterruptions() async {
        let reasons = NotificationCenter.default
            .notifications(named: AVCaptureSession.wasInterruptedNotification)
            .compactMap { notification in
                notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int
            }
        let blocking = [
            AVCaptureSession.InterruptionReason.videoDeviceInUseByAnotherClient.rawValue,
            AVCaptureSession.InterruptionReason.audioDeviceInUseByAnotherClient.rawValue,
        ]
        for await reason in reasons where blocking.contains(reason) {
            eventContinuation.yield(.interrupted)
        }
    }

    private func observeInterruptionEnd() async {
        let ended = NotificationCenter.default
            .notifications(named: AVCaptureSession.interruptionEndedNotification)
            .map { _ in true }
        for await _ in ended {
            eventContinuation.yield(.resumed)
        }
    }

    private func observeRuntimeErrors() async {
        let codes = NotificationCenter.default
            .notifications(named: AVCaptureSession.runtimeErrorNotification)
            .compactMap { notification in
                (notification.userInfo?[AVCaptureSessionErrorKey] as? AVError)?.code
            }
        for await code in codes where code == .mediaServicesWereReset {
            restartAfterReset()
        }
    }

    private func restartAfterReset() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }

    private var isAuthorizedForVideo: Bool {
        get async { await isAuthorized(for: .video) }
    }

    private var isAuthorizedForAudio: Bool {
        get async { await isAuthorized(for: .audio) }
    }

    private func isAuthorized(for mediaType: AVMediaType) async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        if status == .notDetermined {
            return await AVCaptureDevice.requestAccess(for: mediaType)
        }
        return status == .authorized
    }
}
