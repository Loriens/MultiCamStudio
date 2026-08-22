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
        guard let item = player.currentItem else { return }
        player.pause()
        guard await isReadyToPlay(item) else { return }
        let time = startTime + CMTime(seconds: elapsed, preferredTimescale: 600)
        await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        guard player.status == .readyToPlay else { return }
        _ = await player.preroll(atRate: 1)
    }

    func start(at hostTime: CFTimeInterval) {
        guard player.currentItem != nil, player.status == .readyToPlay else { return }
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

    private func isReadyToPlay(_ item: AVPlayerItem) async -> Bool {
        if item.status != .unknown { return item.status == .readyToPlay }
        let (stream, continuation) = AsyncStream.makeStream(of: AVPlayerItem.Status.self)
        let token = item.observe(\.status, options: [.initial, .new]) { current, _ in
            continuation.yield(current.status)
        }
        defer { token.invalidate() }
        for await status in stream where status != .unknown {
            return status == .readyToPlay
        }
        return false
    }
}
