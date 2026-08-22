//
//  FeedViewModel.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

@Observable
final class FeedViewModel {
    var captures: [CapturePlaceholder] = CapturePlaceholder.samples
    var selection: CapturePlaceholder?

    var countLabel: String {
        switch captures.count {
        case 0: "None yet"
        case 1: "1 plate"
        default: "\(captures.count) plates"
        }
    }

    var isViewerPresented: Bool {
        get { selection != nil }
        set { if !newValue { selection = nil } }
    }

    func showNext() {
        move(by: 1)
    }

    func showPrevious() {
        move(by: -1)
    }

    private func move(by offset: Int) {
        guard let current = selection, let index = captures.firstIndex(of: current) else { return }
        selection = captures[(index + offset + captures.count) % captures.count]
    }
}
