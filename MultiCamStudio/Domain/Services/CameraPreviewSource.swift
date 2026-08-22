//
//  CameraPreviewSource.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import QuartzCore

protocol CameraPreviewSource: AnyObject {
    var previewLayer: CALayer { get }

    func devicePoint(for point: CGPoint) -> CGPoint
}
