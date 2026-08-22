//
//  FileImage.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct FileImage: View {
    let url: URL?
    let maxPixelSize: Int
    var caption: String?

    @State
    private var image: CGImage?

    var body: some View {
        content
            .task(id: url) {
                guard let url else {
                    image = nil
                    return
                }
                image = await ImageDownsampler.thumbnail(atFile: url, maxPixelSize: maxPixelSize)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            PlaceholderPlate(caption: caption)
        }
    }
}
