//
//  CaptureMedia.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

struct CaptureMedia: Hashable, Sendable {
    let lens: CaptureLens
    let url: URL
    let posterURL: URL?
    let duration: TimeInterval?
}
