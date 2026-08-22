//
//  AVCaptureDevice+MultiCam.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreMedia
import Foundation

extension AVCaptureDevice {
    private static let preferredPixelCount = 1920 * 1440
    private static let smallestPixelCount = 640 * 480

    func applyBestMultiCamFormat() {
        let candidates = formats.filter(\.isMultiCamSupported)
        let affordable = candidates.filter { pixelCount(of: $0) <= Self.preferredPixelCount }
        guard let format = largest(in: affordable.isEmpty ? candidates : affordable) else { return }
        apply(format)
    }

    func applySmallerMultiCamFormat() -> Bool {
        let activePixelCount = pixelCount(of: activeFormat)
        guard activePixelCount > Self.smallestPixelCount else { return false }
        let smaller = formats.filter { $0.isMultiCamSupported && pixelCount(of: $0) < activePixelCount }
        guard let format = largest(in: smaller) else { return false }
        apply(format)
        return activeFormat == format
    }

    private func largest(in formats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format? {
        formats.max { pixelCount(of: $0) < pixelCount(of: $1) }
    }

    private func pixelCount(of format: AVCaptureDevice.Format) -> Int {
        let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        return Int(dimensions.width) * Int(dimensions.height)
    }

    private func apply(_ format: AVCaptureDevice.Format) {
        guard (try? lockForConfiguration()) != nil else { return }
        defer { unlockForConfiguration() }
        activeFormat = format
    }
}
