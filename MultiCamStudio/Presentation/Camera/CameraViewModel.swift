//
//  CameraViewModel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

@Observable
final class CameraViewModel {
    var mode: CaptureMode = .photo
    var isRecording = false
    var isFrontLeading = false

    func selectMode(_ newMode: CaptureMode) {
        guard !isRecording else { return }
        mode = newMode
    }

    func toggleLeadingCamera() {
        isFrontLeading.toggle()
    }

    func shutterTapped() {
        guard mode == .video else { return }
        isRecording.toggle()
    }
}
