//
//  FrontMediaRecord.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class FrontMediaRecord {
    var lensRawValue: String
    var relativePath: String
    var posterRelativePath: String?
    var duration: TimeInterval?
    var capture: CaptureRecord?

    init(lensRawValue: String, relativePath: String, posterRelativePath: String?, duration: TimeInterval?) {
        self.lensRawValue = lensRawValue
        self.relativePath = relativePath
        self.posterRelativePath = posterRelativePath
        self.duration = duration
    }
}
