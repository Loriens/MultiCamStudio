//
//  CaptureEvent.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

enum CaptureEvent: Sendable, Equatable {
    case interrupted
    case resumed
    case recordingDiscarded
    case shutterFired
    case failed
}
