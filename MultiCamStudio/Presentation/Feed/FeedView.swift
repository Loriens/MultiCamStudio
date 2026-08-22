//
//  FeedView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct FeedView: View {
    @Bindable
    var viewModel: FeedViewModel

    private let columns = [
        GridItem(.flexible(), spacing: Theme.space4),
        GridItem(.flexible(), spacing: Theme.space4),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            if !viewModel.isLoaded {
                LoadingIndicator()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.captures.isEmpty {
                emptySheet
            } else {
                grid
            }
        }
        .foregroundStyle(Theme.text)
        .background(Theme.surface.ignoresSafeArea())
        .fullScreenCover(isPresented: $viewModel.isViewerPresented) {
            CaptureViewerView(viewModel: viewModel)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.space3) {
            Text("Feed")
                .scaledFont(size: 32, relativeTo: .title)
            Hairline()
        }
        .padding(.horizontal, Theme.space6)
        .padding(.top, Theme.space2)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.space4) {
                ForEach(viewModel.captures) { capture in
                    Button {
                        viewModel.selection = capture
                    } label: {
                        CaptureCell(capture: capture)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.space6)
            .padding(.vertical, Theme.space4)
        }
    }

    private var emptySheet: some View {
        VStack(spacing: Theme.space4) {
            PlateMat(inset: 6) {
                PlaceholderPlate()
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
            }
            .frame(width: 92)

            Text("An empty sheet")
                .scaledFont(size: 25, relativeTo: .title2)
            Text("Each plate pairs the rear frame with the face that took it.")
                .scaledFont(size: 13.5)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 46)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
