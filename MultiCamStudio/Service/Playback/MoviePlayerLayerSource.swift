//
//  MoviePlayerLayerSource.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreMedia
import Foundation
import QuartzCore

@MainActor
final class MoviePlayerLayerSource: MoviePlaybackSource {
    private let player = AVPlayer()
    private let videoPlayerLayer: AVPlayerLayer
    private var replayTask: Task<Void, Never>?

    var playerLayer: CALayer { videoPlayerLayer }

    init() {
        videoPlayerLayer = AVPlayerLayer(player: player)
        videoPlayerLayer.videoGravity = .resizeAspectFill
    }

    func play(_ url: URL) {
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        replay()
    }

    func replay() {
        replayTask?.cancel()
        replayTask = Task { [weak self] in
            guard let self else { return }
            await player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            guard !Task.isCancelled else { return }
            player.play()
        }
    }

    func pause() {
        replayTask?.cancel()
        replayTask = nil
        player.pause()
    }

    func resume() {
        guard player.currentItem != nil else { return }
        player.play()
    }

    func stop() {
        replayTask?.cancel()
        replayTask = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
