//
//  Capture.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

struct Capture: Identifiable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    let back: CaptureMedia
    let front: CaptureMedia?

    var isVideo: Bool { back.duration != nil }
}
