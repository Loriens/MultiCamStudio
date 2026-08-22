//
//  CameraView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CameraView: View {
    let camera: CameraModel

    @Environment(\.scenePhase)
    private var scenePhase
    @ScaledMetric(relativeTo: .body)
    private var iconButtonSize = 34.0
    @State
    private var focusPoint: CGPoint?
    @State
    private var flashOpacity = 0.0

    var body: some View {
        VStack(spacing: 0) {
            header
            preview
            controls
        }
        .foregroundStyle(Theme.text)
        .background(Theme.surface.ignoresSafeArea())
        .sensoryFeedback(.impact, trigger: camera.shutterTapCount)
        .task {
            await camera.start()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await camera.start() }
        }
        .onChange(of: camera.flashCount) { _, _ in
            flashOpacity = 0.85
            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
        }
    }

    private var header: some View {
        HStack {
            Text("Multicam")
                .scaledFont(size: 20, weight: .semibold, relativeTo: .title3)
            Spacer()
            Button(action: camera.switchCamera) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .scaledFont(size: 14)
                    .frame(width: iconButtonSize, height: iconButtonSize)
                    .foregroundStyle(Theme.textMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMedium)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(PressableButtonStyle())
            .opacity(camera.isBusy ? 0.5 : 1)
            .disabled(camera.status != .running || camera.isRecording)
        }
        .padding(.horizontal, 22)
        .frame(minHeight: 48)
    }

    private var preview: some View {
        ZStack(alignment: .top) {
            CameraPreview(source: camera.previewSource)
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            focusPoint = value.location
                            camera.focus(at: value.location)
                        }
                )

            if camera.status != .running {
                CameraStatusPlate(status: camera.status)
            }

            if camera.isRecording {
                recordingBadge
                    .padding(.top, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.raised)
        .clipped()
        .overlay { reticle }
        .overlay { flash }
        .overlay(alignment: .bottomLeading) { reviewPlate }
        .animation(.easeInOut(duration: 0.25), value: camera.review == nil)
        .overlay(alignment: .top) { Hairline() }
        .overlay(alignment: .bottom) { Hairline() }
    }

    @ViewBuilder
    private var reticle: some View {
        if let point = focusPoint {
            FocusReticle()
                .position(point)
                .allowsHitTesting(false)
                .transition(.opacity)
                .task(id: point) {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.2)) { focusPoint = nil }
                }
        }
    }

    private var flash: some View {
        Rectangle()
            .fill(Theme.text)
            .opacity(flashOpacity)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var reviewPlate: some View {
        if let review = camera.review {
            CaptureReviewPlate(review: review)
                .padding(14)
                .allowsHitTesting(false)
                .transition(.opacity)
        }
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
            .opacity(camera.isBusy ? 0.5 : 1)

            ShutterButton(
                mode: camera.mode,
                isRecording: camera.isRecording,
                isBusy: camera.isBusy,
                action: camera.shutterTapped
            )
            .disabled(camera.status != .running)
        }
        .padding(.vertical, 22)
    }

    private func modeButton(_ mode: CaptureMode) -> some View {
        let isSelected = camera.mode == mode
        return Button {
            camera.selectMode(mode)
        } label: {
            Text(mode.title.uppercased())
                .scaledFont(size: 10.5, weight: .semibold, relativeTo: .caption)
                .tracking(1.26)
                .foregroundStyle(isSelected ? Color.white : Theme.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isSelected ? Theme.text.opacity(0.16) : Color.clear)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(camera.isRecording)
    }
}
