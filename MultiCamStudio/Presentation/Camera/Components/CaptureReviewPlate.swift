//
//  CaptureReviewPlate.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct CaptureReviewPlate: View {
    let review: CaptureReview

    var body: some View {
        PlateMat {
            content
                .frame(width: 104, height: 139)
                .clipped()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch review {
        case .photo(let image):
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
        case .movie(let duration):
            PlaceholderPlate(caption: "MOV \(Int(duration.rounded()))S")
        case .failure:
            PlaceholderPlate(caption: "FAILED")
        }
    }
}
