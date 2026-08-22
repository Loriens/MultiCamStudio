//
//  CaptureStore.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

protocol CaptureStore: AnyObject {
    nonisolated var changes: AsyncStream<[Capture]> { get }

    func loadCaptures() async throws -> [Capture]
    func savePhotoCapture(back: CapturedPhoto, lens: CaptureLens) async throws
    func saveMovieCapture(back: CapturedMovie, lens: CaptureLens) async throws
}
