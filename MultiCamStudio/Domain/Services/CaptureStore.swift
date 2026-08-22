//
//  CaptureStore.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

@MainActor
protocol CaptureStore: AnyObject {
    nonisolated var changes: AsyncStream<[Capture]> { get }

    func loadCaptures() async throws -> [Capture]
    func savePhotoCapture(_ photos: CapturedPhotoPair) async throws
    func saveMovieCapture(_ movies: CapturedMoviePair) async throws
}
