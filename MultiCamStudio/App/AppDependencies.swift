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

    static func make() async -> AppDependencies {
        async let container = ModelContainerLoader().makeContainer()
        await Task.yield()
        let captureService = CaptureService()
        await Task.yield()
        let backPlayback = MoviePlayerLayerSource()
        let frontPlayback = MoviePlayerLayerSource()
        return AppDependencies(
            captureService: captureService,
            backPlayback: backPlayback,
            frontPlayback: frontPlayback,
            container: await container
        )
    }

    private init(
        captureService: any CameraCaptureService,
        backPlayback: any MoviePlaybackSource,
        frontPlayback: any MoviePlaybackSource,
        container: ModelContainer?
    ) {
        self.captureService = captureService
        self.backPlayback = backPlayback
        self.frontPlayback = frontPlayback
        captureStore = CaptureRepository(
            posterService: PosterGenerator(),
            container: container
        )
    }
}
