//
//  CaptureCell.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CaptureCell: View {
    let item: FeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space1) {
            PlateMat {
                FileImage(url: posterURL, maxPixelSize: 512)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
            }
            .overlay(alignment: .topLeading) { frontInset }
            .overlay(alignment: .bottomTrailing) {
                if let durationLabel = item.capture.durationLabel {
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

            HStack {
                Text(item.plateTitle)
                Spacer()
                Text(lensLabel.uppercased())
                    .tracking(1.1)
            }
            .scaledFont(size: 11, relativeTo: .caption)
            .foregroundStyle(Theme.textSubdued)
        }
    }

    private var posterURL: URL {
        item.capture.back.posterURL ?? item.capture.back.url
    }

    private var lensLabel: String {
        item.capture.front == nil ? item.capture.back.lens.title : "Both"
    }

    @ViewBuilder
    private var frontInset: some View {
        if let front = item.capture.front {
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
