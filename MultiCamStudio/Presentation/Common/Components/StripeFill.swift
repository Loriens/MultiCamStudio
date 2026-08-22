//
//  StripeFill.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct StripeFill: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.raised))
            let band = Theme.stripeBand
            let bands = Path { path in
                var x = -size.height
                while x < size.width + size.height {
                    path.move(to: CGPoint(x: x, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: 0))
                    x += band * 2
                }
            }
            context.stroke(bands, with: .color(Theme.stripe), lineWidth: band)
        }
    }
}
