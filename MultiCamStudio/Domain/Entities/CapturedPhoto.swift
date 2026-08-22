//
//  CapturedPhoto.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

nonisolated struct CapturedPhoto: Sendable {
    let data: Data
    let fileExtension: String
}
