//
//  CameraPreviewView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import QuartzCore
import UIKit

final class CameraPreviewView: UIView {
    private let contentLayer: CALayer

    init(contentLayer: CALayer) {
        self.contentLayer = contentLayer
        super.init(frame: .zero)
        layer.addSublayer(contentLayer)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentLayer.frame = bounds
        CATransaction.commit()
    }
}
