//
//  PlaceholderPlate.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct PlaceholderPlate: View {
    var caption: String?

    var body: some View {
        ZStack {
            StripeFill()
            if let caption {
                Text(caption)
                    .scaledFont(size: 9, relativeTo: .caption2)
                    .tracking(1.44)
                    .foregroundStyle(Theme.textFaint)
            }
        }
        .clipped()
    }
}
