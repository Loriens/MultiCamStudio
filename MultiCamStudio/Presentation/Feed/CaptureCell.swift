//
//  CaptureCell.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CaptureCell: View {
    let capture: CapturePlaceholder

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.space1) {
            PlateMat {
                PlaceholderPlate()
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
            }
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

            HStack {
                Text(capture.plate)
                Spacer()
                Text("REAR")
                    .tracking(1.1)
            }
            .scaledFont(size: 11, relativeTo: .caption)
            .foregroundStyle(Theme.textSubdued)
        }
    }
}
