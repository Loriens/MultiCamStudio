//
//  CaptureService.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation

actor CaptureService: CameraCaptureService {
    private static let interShotDelay = Duration.seconds(1.5)

    nonisolated let events: AsyncStream<CaptureEvent>

    nonisolated var backPreviewSource: CameraPreviewSource { backPreviewLayerSource }

    nonisolated var frontPreviewSource: CameraPreviewSource { frontPreviewLayerSource }

    private nonisolated(unsafe) let captureSession: AVCaptureMultiCamSession
    private nonisolated let backPreviewLayerSource: CameraPreviewLayerSource
    private nonisolated let frontPreviewLayerSource: CameraPreviewLayerSource
    private nonisolated let eventContinuation: AsyncStream<CaptureEvent>.Continuation
    private let deviceLookup = DeviceLookup()

    private lazy var backChannel = CameraChannel(lens: .back, previewSource: backPreviewLayerSource)
    private lazy var frontChannel = CameraChannel(lens: .front, previewSource: frontPreviewLayerSource)

    private var audioInput: AVCaptureDeviceInput?
    private var notificationTask: Task<Void, Never>?
    private var captureMode = CaptureMode.photo
    private var pendingMovieURLs: Set<URL> = []
    private var isSetUp = false

    private var channels: [CameraChannel] { [backChannel, frontChannel] }

    @MainActor
    init() {
        let session = AVCaptureMultiCamSession()
        captureSession = session
        backPreviewLayerSource = CameraPreviewLayerSource(
            session: session,
            isMirrored: false,
            defersStart: false
        )
        frontPreviewLayerSource = CameraPreviewLayerSource(
            session: session,
            isMirrored: true,
            defersStart: true
        )
        let (stream, continuation) = AsyncStream.makeStream(
            of: CaptureEvent.self,
            bufferingPolicy: .unbounded
        )
        events = stream
        eventContinuation = continuation
    }

    func start(in mode: CaptureMode) async throws {
        guard !captureSession.isRunning else { return }
        guard AVCaptureMultiCamSession.isMultiCamSupported else { throw CameraError.multiCamUnsupported }
        guard let cameras = deviceLookup.multiCamPair() else { throw CameraError.cameraUnavailable }
        guard await isAuthorizedForVideo else { throw CameraError.notAuthorized }

        try await setUpSession(with: cameras)
        observeSessionNotifications()
        captureSession.startRunning()
        await startRotationTracking()
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
        try applyMovieOutputs(for: mode)
        reduceCostIfNeeded()
        captureMode = mode
    }

    private func applyMovieOutputs(for mode: CaptureMode) throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        switch mode {
        case .photo:
            for channel in channels {
                captureSession.removeOutput(channel.movieCapture.output)
            }
        case .video:
            do {
                for channel in channels {
                    guard let videoPort = channel.videoPort else { throw CameraError.addOutputFailed }
                    try add(channel.movieCapture.output, video: videoPort, audio: channel.audioPort)
                    channel.movieCapture.configureConnection()
                    channel.movieCapture.setVideoRotationAngle(channel.captureRotationAngle)
                }
            } catch {
                for channel in channels {
                    captureSession.removeOutput(channel.movieCapture.output)
                }
                throw error
            }
        }
    }

    func focusAndExpose(at devicePoint: CGPoint, lens: CaptureLens) {
        guard let device = channel(for: lens).device else { return }
        try? lockAndFocus(device, at: devicePoint)
    }

    func capturePhoto() async throws -> CapturedPhotoPair {
        eventContinuation.yield(.shutterFired)
        let back = try await backChannel.photoCapture.capturePhoto()
        try await Task.sleep(for: Self.interShotDelay)
        eventContinuation.yield(.shutterFired)
        let front = try? await frontChannel.photoCapture.capturePhoto()
        return CapturedPhotoPair(back: back, front: front)
    }

    func startRecording() async throws {
        discardPendingMovies()
        let backURL = try backChannel.movieCapture.startRecording()
        pendingMovieURLs.insert(backURL)
        if let frontURL = try? frontChannel.movieCapture.startRecording() {
            pendingMovieURLs.insert(frontURL)
        }
    }

    func stopRecording() async throws -> CapturedMoviePair {
        let backElapsed = backChannel.movieCapture.recordedDuration
        let frontElapsed = frontChannel.movieCapture.isRecording ? frontChannel.movieCapture.recordedDuration : nil
        let synchronizedDuration = min(backElapsed, frontElapsed ?? backElapsed)

        try backChannel.movieCapture.stop()
        try? frontChannel.movieCapture.stop()

        let back = try await backChannel.movieCapture.finishedMovie(
            startOffset: backElapsed - synchronizedDuration,
            duration: synchronizedDuration
        )
        var front: CapturedMovie?
        if let frontElapsed {
            front = try? await frontChannel.movieCapture.finishedMovie(
                startOffset: frontElapsed - synchronizedDuration,
                duration: synchronizedDuration
            )
        }
        return CapturedMoviePair(back: back, front: front)
    }

    private func channel(for lens: CaptureLens) -> CameraChannel {
        lens == .back ? backChannel : frontChannel
    }

    private func setUpSession(with cameras: CameraPair) async throws {
        guard !isSetUp else { return }

        do {
            try await configureGraph(with: cameras)
        } catch {
            tearDownGraph()
            throw error
        }
        reduceCostIfNeeded()
        for channel in channels {
            channel.photoCapture.prepare()
        }
        captureMode = .photo
        isSetUp = true
    }

    private func configureGraph(with cameras: CameraPair) async throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for channel in channels {
            try configure(channel, device: cameras.device(for: channel.lens))
        }
        for channel in channels {
            guard let videoPort = channel.videoPort else { throw CameraError.addInputFailed }
            try await channel.previewSource.connect(port: videoPort, in: captureSession)
        }
    }

    private func tearDownGraph() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        for connection in captureSession.connections {
            captureSession.removeConnection(connection)
        }
        for output in captureSession.outputs {
            captureSession.removeOutput(output)
        }
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        audioInput = nil
        for channel in channels {
            channel.device = nil
            channel.input = nil
            channel.videoPort = nil
            channel.audioPort = nil
        }
    }

    private func configure(_ channel: CameraChannel, device: AVCaptureDevice) throws {
        device.applyBestMultiCamFormat()
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else { throw CameraError.addInputFailed }
        captureSession.addInputWithNoConnections(input)

        let videoPorts = input.ports(
            for: .video,
            sourceDeviceType: device.deviceType,
            sourceDevicePosition: device.position
        )
        guard let videoPort = videoPorts.first else { throw CameraError.addInputFailed }

        channel.device = device
        channel.input = input
        channel.videoPort = videoPort

        try add(channel.photoCapture.output, video: videoPort, audio: nil)
        channel.photoCapture.deferStart()
    }

    private func add(
        _ output: AVCaptureOutput,
        video videoPort: AVCaptureInput.Port,
        audio audioPort: AVCaptureInput.Port?
    ) throws {
        guard captureSession.canAddOutput(output) else { throw CameraError.addOutputFailed }
        captureSession.addOutputWithNoConnections(output)
        do {
            try addConnection(from: videoPort, to: output)
        } catch {
            captureSession.removeOutput(output)
            throw error
        }
        if let audioPort {
            try? addConnection(from: audioPort, to: output)
        }
    }

    private func addConnection(from port: AVCaptureInput.Port, to output: AVCaptureOutput) throws {
        let connection = AVCaptureConnection(inputPorts: [port], output: output)
        guard captureSession.canAddConnection(connection) else { throw CameraError.addOutputFailed }
        captureSession.addConnection(connection)
    }

    private func addAudioInputIfPermitted() async {
        guard audioInput == nil else { return }
        guard await isAuthorizedForAudio else { return }
        guard let microphone = deviceLookup.defaultMicrophone else { return }
        guard let input = try? AVCaptureDeviceInput(device: microphone) else { return }
        guard captureSession.canAddInput(input) else { return }

        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.addInputWithNoConnections(input)
        audioInput = input
        for channel in channels {
            channel.audioPort =
                input.ports(
                    for: .audio,
                    sourceDeviceType: microphone.deviceType,
                    sourceDevicePosition: channel.lens == .back ? .back : .front
                ).first
        }
        if backChannel.audioPort == nil {
            backChannel.audioPort = input.ports.first { $0.mediaType == .audio }
        }
    }

    private func reduceCostIfNeeded() {
        var reduced = true
        while reduced, captureSession.hardwareCost > 1 || captureSession.systemPressureCost > 1 {
            reduced =
                frontChannel.device?.applySmallerMultiCamFormat() == true
                || backChannel.device?.applySmallerMultiCamFormat() == true
                || reduceFrameRate()
        }
    }

    private func reduceFrameRate() -> Bool {
        var reduced = false
        for channel in channels {
            guard let input = channel.input else { continue }
            let duration = input.device.activeVideoMinFrameDuration
            guard duration.value > 0 else { continue }
            let nextRate = Double(duration.timescale) / Double(duration.value) - 10
            guard nextRate >= 15 else { continue }
            guard (try? input.device.lockForConfiguration()) != nil else { continue }
            input.videoMinFrameDurationOverride = CMTime(value: 1, timescale: CMTimeScale(nextRate))
            input.device.unlockForConfiguration()
            reduced = true
        }
        return reduced
    }

    private func startRotationTracking() async {
        for channel in channels {
            guard let device = channel.device else { continue }
            channel.rotationTask?.cancel()
            let angles = await channel.previewSource.trackRotation(for: device)
            channel.rotationTask = Task {
                for await angle in angles {
                    applyCaptureRotation(angle, to: channel)
                }
            }
        }
    }

    private func applyCaptureRotation(_ angle: CGFloat, to channel: CameraChannel) {
        channel.captureRotationAngle = angle
        channel.photoCapture.setVideoRotationAngle(angle)
        channel.movieCapture.setVideoRotationAngle(angle)
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

    private func abandonRecording() async {
        guard channels.contains(where: { $0.movieCapture.hasPendingRecording }) else { return }
        for channel in channels {
            await channel.movieCapture.discard()
        }
        discardPendingMovies()
        eventContinuation.yield(.recordingDiscarded)
    }

    private func discardPendingMovies() {
        for url in pendingMovieURLs {
            try? FileManager.default.removeItem(at: url)
        }
        pendingMovieURLs.removeAll()
    }

    private func purgeOrphanedMovies() {
        guard !channels.contains(where: { $0.movieCapture.isRecording }) else { return }
        let fileManager = FileManager.default
        let contents = try? fileManager.contentsOfDirectory(
            at: .temporaryDirectory,
            includingPropertiesForKeys: nil
        )
        for url in contents ?? [] where url.pathExtension == "mov" && !pendingMovieURLs.contains(url) {
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
            AVCaptureSession.InterruptionReason.videoDeviceNotAvailableDueToSystemPressure.rawValue,
        ]
        for await reason in reasons {
            await abandonRecording()
            guard blocking.contains(reason) else { continue }
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
        for await code in codes {
            await abandonRecording()
            recover(from: code)
        }
    }

    private func recover(from code: AVError.Code) {
        guard code == .mediaServicesWereReset else {
            eventContinuation.yield(.failed)
            return
        }
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
