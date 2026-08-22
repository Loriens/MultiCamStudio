//
//  CapturedMovie.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

struct CapturedMovie: Sendable {
    let url: URL
    let startOffset: TimeInterval
    let duration: TimeInterval
}
