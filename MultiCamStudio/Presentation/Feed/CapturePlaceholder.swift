//
//  CapturePlaceholder.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

struct CapturePlaceholder: Identifiable, Hashable {
    let id = UUID()
    let plate: String
    let videoSeconds: Int?

    var isVideo: Bool { videoSeconds != nil }

    var durationLabel: String? {
        videoSeconds.map { "\($0)s" }
    }

    var kindLabel: String {
        guard let videoSeconds else { return "Photograph" }
        return "Video \(videoSeconds)s"
    }

    static let samples: [CapturePlaceholder] = [
        CapturePlaceholder(plate: "Plate VI", videoSeconds: 8),
        CapturePlaceholder(plate: "Plate V", videoSeconds: nil),
        CapturePlaceholder(plate: "Plate IV", videoSeconds: nil),
        CapturePlaceholder(plate: "Plate III", videoSeconds: 12),
        CapturePlaceholder(plate: "Plate II", videoSeconds: nil),
        CapturePlaceholder(plate: "Plate I", videoSeconds: nil),
    ]
}
