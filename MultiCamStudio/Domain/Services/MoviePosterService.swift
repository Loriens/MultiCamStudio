//
//  MoviePosterService.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

nonisolated protocol MoviePosterService: Actor {
    func posterJPEG(for movieURL: URL) async throws -> Data
}
