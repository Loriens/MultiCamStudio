//
//  ModelContainerLoader.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import SwiftData

actor ModelContainerLoader {
    func makeContainer() -> ModelContainer? {
        try? ModelContainer(
            for: CaptureRecord.self,
            BackMediaRecord.self,
            FrontMediaRecord.self
        )
    }
}
