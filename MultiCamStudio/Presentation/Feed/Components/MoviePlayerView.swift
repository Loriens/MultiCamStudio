//
//  MoviePlayerView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct MoviePlayerView: UIViewRepresentable {
    let playerLayer: CALayer

    func makeUIView(context: Context) -> MoviePlayerLayerView {
        MoviePlayerLayerView(contentLayer: playerLayer)
    }

    func updateUIView(_ uiView: MoviePlayerLayerView, context: Context) {
        uiView.contentLayer = playerLayer
    }
}
