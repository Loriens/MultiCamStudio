//
//  FrontMediaRecord.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import SwiftData

@Model
final class FrontMediaRecord {
    var lensRawValue: String
    var relativePath: String
    var posterRelativePath: String?
    var startOffset: TimeInterval = 0
    var duration: TimeInterval?
    var capture: CaptureRecord?

    init(
        lensRawValue: String,
        relativePath: String,
        posterRelativePath: String?,
        startOffset: TimeInterval,
        duration: TimeInterval?
    ) {
        self.lensRawValue = lensRawValue
        self.relativePath = relativePath
        self.posterRelativePath = posterRelativePath
        self.startOffset = startOffset
        self.duration = duration
    }
}
