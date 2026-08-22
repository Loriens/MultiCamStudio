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
    private var startTime = CMTime.zero

    var playerLayer: CALayer { videoPlayerLayer }

    var elapsed: TimeInterval? {
        guard player.currentItem != nil else { return nil }
        return max((player.currentTime() - startTime).seconds, 0)
    }

    init() {
        videoPlayerLayer = AVPlayerLayer(player: player)
        videoPlayerLayer.videoGravity = .resizeAspectFill
        player.automaticallyWaitsToMinimizeStalling = false
    }

    func load(_ url: URL, from startOffset: TimeInterval, for duration: TimeInterval) {
        startTime = CMTime(seconds: startOffset, preferredTimescale: 600)
        let item = AVPlayerItem(url: url)
        item.forwardPlaybackEndTime = startTime + CMTime(seconds: duration, preferredTimescale: 600)
        player.replaceCurrentItem(with: item)
    }

    func prepare(at elapsed: TimeInterval) async {
        guard player.currentItem != nil else { return }
        player.pause()
        let time = startTime + CMTime(seconds: elapsed, preferredTimescale: 600)
        await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        _ = await player.preroll(atRate: 1)
    }

    func start(at hostTime: CFTimeInterval) {
        guard player.currentItem != nil else { return }
        player.setRate(
            1,
            time: .invalid,
            atHostTime: CMTime(seconds: hostTime, preferredTimescale: 1_000_000_000)
        )
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        startTime = .zero
    }
}
