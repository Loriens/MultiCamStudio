//
//  MoviePlayerLayerView.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import QuartzCore
import UIKit

final class MoviePlayerLayerView: UIView {
    var contentLayer: CALayer {
        didSet {
            guard contentLayer !== oldValue else { return }
            oldValue.removeFromSuperlayer()
            mount()
        }
    }

    init(contentLayer: CALayer) {
        self.contentLayer = contentLayer
        super.init(frame: .zero)
        mount()
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

    private func mount() {
        contentLayer.removeFromSuperlayer()
        layer.addSublayer(contentLayer)
        setNeedsLayout()
    }
}
