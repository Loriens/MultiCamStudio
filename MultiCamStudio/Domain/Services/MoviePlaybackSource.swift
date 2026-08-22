//
//  MoviePlaybackSource.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import QuartzCore

@MainActor
protocol MoviePlaybackSource: AnyObject {
    var playerLayer: CALayer { get }
    var elapsed: TimeInterval? { get }

    func load(_ url: URL, from startOffset: TimeInterval, for duration: TimeInterval)
    func prepare(at elapsed: TimeInterval) async
    func start(at hostTime: CFTimeInterval)
    func pause()
    func stop()
}
