//
//  FeedViewModel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import Observation
import QuartzCore

@MainActor
@Observable
final class FeedViewModel {
    private(set) var captures: [Capture] = []
    private(set) var isLoaded = false
    private(set) var isStoreUnavailable = false
    var selection: Capture?

    private static let startLeadTime = 0.1

    var backPlayerLayer: CALayer { backPlayback.playerLayer }

    var frontPlayerLayer: CALayer { frontPlayback.playerLayer }

    private let captureStore: any CaptureStore
    private let backPlayback: any MoviePlaybackSource
    private let frontPlayback: any MoviePlaybackSource
    private var storeTask: Task<Void, Never>?
    private var playbackTask: Task<Void, Never>?
    private var hasStarted = false

    init(
        captureStore: any CaptureStore,
        backPlayback: any MoviePlaybackSource,
        frontPlayback: any MoviePlaybackSource
    ) {
        self.captureStore = captureStore
        self.backPlayback = backPlayback
        self.frontPlayback = frontPlayback
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await load()
        storeTask = Task { [weak self] in
            guard let self else { return }
            for await captures in captureStore.changes {
                apply(captures)
            }
        }
    }

    var isViewerPresented: Bool {
        get { selection != nil }
        set { if !newValue { selection = nil } }
    }

    func showNext() {
        move(by: 1)
    }

    func showPrevious() {
        move(by: -1)
    }

    func showPlayback() {
        guard let capture = selection, let backDuration = capture.back.duration else {
            stopPlayback()
            return
        }
        backPlayback.load(capture.back.url, from: capture.back.startOffset, for: backDuration)
        if let front = capture.front, let frontDuration = front.duration {
            frontPlayback.load(front.url, from: front.startOffset, for: frontDuration)
        } else {
            frontPlayback.stop()
        }
        play(from: 0)
    }

    func replay() {
        play(from: 0)
    }

    func pausePlayback() {
        playbackTask?.cancel()
        backPlayback.pause()
        frontPlayback.pause()
    }

    func resumePlayback() {
        guard let elapsed = [backPlayback.elapsed, frontPlayback.elapsed].compactMap({ $0 }).min() else { return }
        play(from: elapsed)
    }

    func stopPlayback() {
        playbackTask?.cancel()
        backPlayback.stop()
        frontPlayback.stop()
    }

    private func play(from elapsed: TimeInterval) {
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            guard let self else { return }
            await backPlayback.prepare(at: elapsed)
            await frontPlayback.prepare(at: elapsed)
            guard !Task.isCancelled else { return }
            let hostTime = CACurrentMediaTime() + Self.startLeadTime
            backPlayback.start(at: hostTime)
            frontPlayback.start(at: hostTime)
        }
    }

    private func load() async {
        do {
            apply(try await captureStore.loadCaptures())
        } catch {
            isStoreUnavailable = true
        }
        isLoaded = true
    }

    private func apply(_ newCaptures: [Capture]) {
        captures = newCaptures
        guard let selection else { return }
        self.selection = captures.first { $0.id == selection.id }
    }

    private func move(by offset: Int) {
        guard let current = selection, let index = captures.firstIndex(of: current) else { return }
        selection = captures[(index + offset + captures.count) % captures.count]
    }
}
