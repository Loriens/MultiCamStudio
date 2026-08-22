//
//  CaptureStoreError.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

nonisolated enum CaptureStoreError: Error, Sendable {
    case storeUnavailable
    case writeFailed
}
