//
//  ImageDownsampler.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import CoreGraphics
import Foundation
import ImageIO

enum ImageDownsampler {
    @concurrent
    static func thumbnail(atFile url: URL, maxPixelSize: Int) async -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
