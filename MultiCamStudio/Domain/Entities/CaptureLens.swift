//
//  CaptureLens.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

nonisolated enum CaptureLens: String, Sendable {
    case back
    case front

    var title: String {
        switch self {
        case .back: "Rear"
        case .front: "Front"
        }
    }
}
