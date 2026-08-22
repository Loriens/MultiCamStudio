//
//  CameraView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CameraView: View {
    let viewModel: CameraViewModel

    @ScaledMetric(relativeTo: .body)
    private var iconButtonSize = 34.0

    var body: some View {
        VStack(spacing: 0) {
            header
            preview
            controls
        }
        .foregroundStyle(Theme.text)
        .background(Theme.surface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Text("Multicam")
                .scaledFont(size: 20, weight: .semibold, relativeTo: .title3)
            Spacer()
            Button(action: viewModel.toggleLeadingCamera) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .scaledFont(size: 14)
                    .frame(width: iconButtonSize, height: iconButtonSize)
                    .foregroundStyle(Theme.textMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .frame(minHeight: 48)
    }

    private var preview: some View {
        ZStack(alignment: .topLeading) {
            PlaceholderPlate(caption: viewModel.isFrontLeading ? "FRONT" : "REAR")

            PlaceholderPlate(caption: viewModel.isFrontLeading ? "REAR" : "FRONT")
                .frame(width: 104, height: 139)
                .overlay(Rectangle().strokeBorder(Theme.text.opacity(0.9), lineWidth: 3))
                .padding(14)

            if viewModel.isRecording {
                recordingBadge
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.raised)
        .clipped()
        .overlay(alignment: .top) { Hairline() }
        .overlay(alignment: .bottom) { Hairline() }
        .animation(.easeInOut(duration: 0.34), value: viewModel.isFrontLeading)
    }

    private var recordingBadge: some View {
        HStack(spacing: 7) {
            PulsingDot()
            Text("REC")
                .scaledFont(size: 11, relativeTo: .caption)
                .tracking(1.1)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(Theme.surface.opacity(0.6))
        .overlay(Rectangle().strokeBorder(Theme.text.opacity(0.5), lineWidth: 1))
        .fixedSize()
    }

    private var controls: some View {
        VStack(spacing: Theme.space4) {
            HStack(spacing: 0) {
                modeButton(.photo)
                Rectangle()
                    .fill(Theme.border)
                    .frame(width: 1)
                modeButton(.video)
            }
            .fixedSize()
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMedium)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )

            shutter
        }
        .padding(.vertical, 22)
    }

    private func modeButton(_ mode: CaptureMode) -> some View {
        let isSelected = viewModel.mode == mode
        return Button {
            viewModel.selectMode(mode)
        } label: {
            Text(mode.title.uppercased())
                .scaledFont(size: 10.5, weight: .semibold, relativeTo: .caption)
                .tracking(1.26)
                .foregroundStyle(isSelected ? Color.white : Theme.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? Theme.text.opacity(0.16) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var shutter: some View {
        let core = RoundedRectangle(cornerRadius: viewModel.isRecording ? Theme.radiusSmall : 28)
        return Button(action: viewModel.shutterTapped) {
            ZStack {
                Circle()
                    .strokeBorder(Theme.text.opacity(0.24), lineWidth: 1.5)
                core
                    .fill(viewModel.isRecording ? Theme.text : Color.clear)
                    .overlay(core.strokeBorder(Theme.text, lineWidth: 1))
                    .padding(viewModel.isRecording ? 24 : 12)
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isRecording)
    }
}
