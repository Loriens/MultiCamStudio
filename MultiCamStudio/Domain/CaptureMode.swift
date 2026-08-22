//
//  CaptureMode.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

nonisolated enum CaptureMode: CaseIterable, Identifiable, Sendable {
    case photo
    case video

    var id: Self { self }

    var title: String {
        switch self {
        case .photo: "Photo"
        case .video: "Video"
        }
    }
}
