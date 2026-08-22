//
//  Capture+Labels.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

extension Capture {
    var durationLabel: String? {
        back.duration.map { "\(Int($0.rounded()))s" }
    }

    var kindLabel: String {
        guard let durationLabel else { return "Photograph" }
        return "Video \(durationLabel)"
    }
}
