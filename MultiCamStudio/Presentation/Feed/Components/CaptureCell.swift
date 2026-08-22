//
//  CaptureCell.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CaptureCell: View {
    let capture: Capture

    var body: some View {
        PlateMat {
            FileImage(url: posterURL, maxPixelSize: 512)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .overlay(alignment: .topLeading) { frontInset }
        .overlay(alignment: .bottomTrailing) {
            if let durationLabel = capture.durationLabel {
                Text("▶ \(durationLabel)")
                    .scaledFont(size: 9.5, relativeTo: .caption2)
                    .tracking(0.76)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.surface.opacity(0.65))
                    .overlay(Rectangle().strokeBorder(Theme.text.opacity(0.5), lineWidth: 1))
                    .padding(10)
            }
        }
    }

    private var posterURL: URL {
        capture.back.posterURL ?? capture.back.url
    }

    @ViewBuilder
    private var frontInset: some View {
        if let front = capture.front {
            FileImage(url: front.posterURL ?? front.url, maxPixelSize: 256)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .frame(width: 30)
                .padding(2)
                .background(Theme.raised)
                .overlay(Rectangle().strokeBorder(Theme.text.opacity(0.28), lineWidth: 1))
                .padding(9)
        }
    }
}
