//
//  CaptureMode.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

enum CaptureMode: CaseIterable, Identifiable {
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
