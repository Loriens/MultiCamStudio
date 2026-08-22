//
//  LaunchView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        Text("MultiCam Studio")
            .scaledFont(size: 32, relativeTo: .title)
            .tracking(1.6)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.surface.ignoresSafeArea())
    }
}
