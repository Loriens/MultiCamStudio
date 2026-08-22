//
//  RootTabView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct RootTabView: View {
    @State
    private var camera: CameraModel
    @State
    private var feedViewModel: FeedViewModel

    init() {
        let captureStore = CaptureRepository(posterService: MoviePosterGenerator())
        _camera = State(
            initialValue: CameraModel(captureService: CaptureService(), captureStore: captureStore)
        )
        _feedViewModel = State(
            initialValue: FeedViewModel(captureStore: captureStore, playback: MoviePlayerLayerSource())
        )
    }

    var body: some View {
        TabView {
            CameraView(camera: camera)
                .tabItem { Label("Camera", systemImage: "camera") }
                .toolbarBackground(Theme.surface, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
            FeedView(viewModel: feedViewModel)
                .tabItem { Label("Feed", systemImage: "square.grid.2x2") }
                .toolbarBackground(Theme.surface, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
        }
        .tint(Theme.text)
        .preferredColorScheme(.dark)
    }
}
