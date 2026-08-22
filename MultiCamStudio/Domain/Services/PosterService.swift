//
//  PosterService.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

protocol PosterService: Actor {
    func posterJPEG(for movieURL: URL) async throws -> Data
    func posterJPEG(forPhotoAt photoURL: URL) async throws -> Data
}
