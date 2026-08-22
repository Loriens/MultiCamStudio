//
//  FeedViewModel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import Observation
import QuartzCore

@Observable
final class FeedViewModel {
    private(set) var captures: [FeedItem] = []
    private(set) var isStoreUnavailable = false
    var selection: FeedItem?

    var playerLayer: CALayer { playback.playerLayer }

    private let captureStore: any CaptureStore
    private let playback: any MoviePlaybackSource
    private var storeTask: Task<Void, Never>?

    init(captureStore: any CaptureStore, playback: any MoviePlaybackSource) {
        self.captureStore = captureStore
        self.playback = playback
        storeTask = Task { [weak self] in
            guard let self else { return }
            await load()
            for await captures in captureStore.changes {
                apply(captures)
            }
        }
    }

    var countLabel: String {
        switch captures.count {
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
        guard let selection, selection.capture.isVideo else {
            playback.stop()
            return
        }
        playback.play(selection.capture.back.url)
    }

    func replay() {
        playback.replay()
    }

    func stopPlayback() {
        playback.stop()
    }

    private func load() async {
        do {
            apply(try await captureStore.loadCaptures())
        } catch {
            isStoreUnavailable = true
        }
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
