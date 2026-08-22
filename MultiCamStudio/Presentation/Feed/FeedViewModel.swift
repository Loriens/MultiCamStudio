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
    private(set) var captures: [FeedItem] = []
    private(set) var isLoaded = false
    private(set) var isStoreUnavailable = false
    var selection: FeedItem?

    var backPlayerLayer: CALayer { backPlayback.playerLayer }

    var frontPlayerLayer: CALayer { frontPlayback.playerLayer }

    private let captureStore: any CaptureStore
    private let backPlayback: any MoviePlaybackSource
    private let frontPlayback: any MoviePlaybackSource
    private var storeTask: Task<Void, Never>?
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

    var countLabel: String {
        guard isLoaded else { return "" }
        return switch captures.count {
        case 0: "None yet"
        case 1: "1 plate"
        default: "\(captures.count) plates"
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
        guard let capture = selection?.capture, capture.isVideo else {
            stopPlayback()
            return
        }
        backPlayback.play(capture.back.url)
        if let front = capture.front, front.duration != nil {
            frontPlayback.play(front.url)
        } else {
            frontPlayback.stop()
        }
    }

    func replay() {
        backPlayback.replay()
        frontPlayback.replay()
    }

    func pausePlayback() {
        backPlayback.pause()
        frontPlayback.pause()
    }

    func resumePlayback() {
        backPlayback.resume()
        frontPlayback.resume()
    }

    func stopPlayback() {
        backPlayback.stop()
        frontPlayback.stop()
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
        let count = newCaptures.count
        captures = newCaptures.enumerated().map { index, capture in
            FeedItem(capture: capture, plateTitle: PlateNumber.title(for: count - index))
        }
        guard let selection else { return }
        self.selection = captures.first { $0.id == selection.id }
    }

    private func move(by offset: Int) {
        guard let current = selection, let index = captures.firstIndex(of: current) else { return }
        selection = captures[(index + offset + captures.count) % captures.count]
    }
}
