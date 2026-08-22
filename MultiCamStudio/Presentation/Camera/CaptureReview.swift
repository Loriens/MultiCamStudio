//
//  CaptureReview.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import Foundation

enum CaptureReview {
    case photo(CGImage)
    case movie(duration: TimeInterval)
    case failure
}
