//
//  AppDependencies.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppDependencies {
    let captureService: any CameraCaptureService
    let captureStore: any CaptureStore
    let backPlayback: any MoviePlaybackSource
    let frontPlayback: any MoviePlaybackSource

    init(container: ModelContainer?) {
        captureService = CaptureService()
        captureStore = CaptureRepository(
            posterService: MoviePosterGenerator(),
            container: container
        )
        backPlayback = MoviePlayerLayerSource()
        frontPlayback = MoviePlayerLayerSource()
    }
}
