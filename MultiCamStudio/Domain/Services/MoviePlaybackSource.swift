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

    func play(_ url: URL)
    func replay()
    func pause()
    func resume()
    func stop()
}
