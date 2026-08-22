//
//  CaptureViewerView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CaptureViewerView: View {
    let viewModel: FeedViewModel

    @Environment(\.dismiss)
    private var dismiss
    @State
    private var isFrontLeading = false
    @ScaledMetric(relativeTo: .body)
    private var iconButtonSize = 34.0

    var body: some View {
        VStack(spacing: 0) {
            header
            plate
            footer
        }
        .foregroundStyle(Theme.text)
        .background(Theme.surface.ignoresSafeArea())
        .onChange(of: viewModel.selection, initial: true) {
            isFrontLeading = false
            viewModel.showPlayback()
        }
        .onDisappear { viewModel.stopPlayback() }
    }

    private var capture: Capture? {
        viewModel.selection?.capture
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .scaledFont(size: 14)
                    .frame(width: iconButtonSize, height: iconButtonSize)
                    .foregroundStyle(Theme.textMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
            Text(title.uppercased())
                .scaledFont(size: 10.5, relativeTo: .caption)
                .tracking(1.68)
                .foregroundStyle(Theme.textSubdued)
            Spacer()

            Color.clear
                .frame(width: iconButtonSize, height: iconButtonSize)
        }
        .padding(.horizontal, 22)
        .frame(minHeight: 48)
    }

    private var title: String {
        let plateTitle = viewModel.selection?.plateTitle ?? ""
        return "\(plateTitle) · \(capture?.kindLabel ?? "")"
    }

    private var plate: some View {
        PlateMat(inset: 6) {
            media(isLeading: true)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay(alignment: .topLeading) { inset }
        }
        .padding(.horizontal, 22)
    }

    @ViewBuilder
    private var inset: some View {
        if hasFrontMedia {
            Button {
                isFrontLeading.toggle()
            } label: {
                insetPlate
            }
            .buttonStyle(.plain)
            .padding(10)
        } else {
            insetPlate
                .padding(10)
        }
    }

    private var insetPlate: some View {
        media(isLeading: false)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .frame(width: 80)
            .padding(4)
            .background(Theme.raised)
            .overlay(Rectangle().strokeBorder(Theme.text.opacity(0.28), lineWidth: 1))
    }

    private var hasFrontMedia: Bool {
        capture?.front != nil
    }

    @ViewBuilder
    private func media(isLeading: Bool) -> some View {
        let showsFront = isLeading == isFrontLeading
        if showsFront {
            FileImage(url: capture?.front?.url, maxPixelSize: 2048, caption: "FRONT")
        } else if capture?.isVideo == true {
            MoviePlayerView(playerLayer: viewModel.playerLayer)
        } else {
            FileImage(url: capture?.back.url, maxPixelSize: 2048, caption: "REAR")
        }
    }

    private var footer: some View {
        VStack(spacing: Theme.space3) {
            if hasFrontMedia {
                Text("Tap the inset to change which camera leads.")
                    .scaledFont(size: 12.5)
                    .italic()
                    .foregroundStyle(Theme.textSubdued)
                    .multilineTextAlignment(.center)
            }

            if capture?.isVideo == true {
                Button {
                    viewModel.replay()
                } label: {
                    Text("Replay")
                        .scaledFont(size: 13.5, weight: .semibold)
                        .tracking(1.62)
                        .textCase(.uppercase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusMedium)
                                .strokeBorder(Theme.text, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Hairline()
                .padding(.vertical, Theme.space1)

            HStack {
                Button("← Previous") { viewModel.showPrevious() }
                Spacer()
                Button("Next →") { viewModel.showNext() }
            }
            .buttonStyle(.plain)
            .scaledFont(size: 13.5, weight: .semibold)
            .tracking(1.62)
            .textCase(.uppercase)
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
    }
}
