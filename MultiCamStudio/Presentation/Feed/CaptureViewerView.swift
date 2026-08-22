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
    @Environment(\.scenePhase)
    private var scenePhase
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.resumePlayback()
            } else {
                viewModel.pausePlayback()
            }
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
            ZStack(alignment: .topLeading) {
                surface(.back)
                surface(.front)
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .padding(.horizontal, 22)
    }

    private func surface(_ lens: CaptureLens) -> some View {
        let isLeading = (lens == .front) == isFrontLeading
        return media(for: lens)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .frame(width: isLeading ? nil : 80)
            .padding(isLeading ? 0 : 4)
            .background(isLeading ? Color.clear : Theme.raised)
            .overlay(
                Rectangle()
                    .strokeBorder(isLeading ? Color.clear : Theme.text.opacity(0.28), lineWidth: 1)
            )
            .padding(isLeading ? 0 : 10)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: isLeading ? .center : .topLeading
            )
            .zIndex(isLeading ? 0 : 1)
            .onTapGesture {
                guard !isLeading, hasFrontMedia else { return }
                isFrontLeading.toggle()
            }
    }

    @ViewBuilder
    private func media(for lens: CaptureLens) -> some View {
        let media = lens == .back ? capture?.back : capture?.front
        if media?.duration != nil {
            MoviePlayerView(
                playerLayer: lens == .back ? viewModel.backPlayerLayer : viewModel.frontPlayerLayer
            )
        } else {
            FileImage(url: media?.url, maxPixelSize: 2048, caption: lens.title.uppercased())
        }
    }

    private var hasFrontMedia: Bool {
        capture?.front != nil
    }

    private var hasFrontVideo: Bool {
        capture?.front?.duration != nil
    }

    private var footer: some View {
        VStack(spacing: Theme.space3) {
            if capture?.isVideo == true {
                Button {
                    viewModel.replay()
                } label: {
                    Text(hasFrontVideo ? "Replay both" : "Replay")
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
        .padding(.bottom, Theme.space3)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
