//
//  MultiCamStudioApp.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 21/08/2026.
//

import SwiftUI

@main
struct MultiCamStudioApp: App {
    @State
    private var dependencies: AppDependencies?

    var body: some Scene {
        WindowGroup {
            Group {
                if let dependencies {
                    RootTabView(dependencies: dependencies)
                } else {
                    LaunchView()
                }
            }
            .preferredColorScheme(.dark)
            .task {
                guard dependencies == nil else { return }
                let container = await ModelContainerLoader().makeContainer()
                dependencies = AppDependencies(container: container)
            }
        }
    }
}
