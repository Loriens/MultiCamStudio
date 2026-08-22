//
//  CameraPreview.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CameraPreview: UIViewRepresentable {
    let source: CameraPreviewSource

    func makeUIView(context: Context) -> CameraPreviewView {
        CameraPreviewView(contentLayer: source.previewLayer)
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}
