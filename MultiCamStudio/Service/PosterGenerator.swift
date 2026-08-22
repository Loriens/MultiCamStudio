//
//  PosterGenerator.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import ImageIO
import UniformTypeIdentifiers

actor PosterGenerator: PosterService {
    private static let maxPixelSize = 1024

    func posterJPEG(for movieURL: URL) async throws -> Data {
        let asset = AVURLAsset(url: movieURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: Self.maxPixelSize, height: Self.maxPixelSize)

        let time = CMTime(seconds: 0, preferredTimescale: 600)
        let image = try await generator.image(at: time).image
        return try encode(image)
    }

    func posterJPEG(forPhotoAt photoURL: URL) async throws -> Data {
        guard let source = CGImageSourceCreateWithURL(photoURL as CFURL, nil) else {
            throw CaptureStoreError.writeFailed
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.maxPixelSize,
        ]
        guard
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            throw CaptureStoreError.writeFailed
        }
        return try encode(image)
    }

    private func encode(_ image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            throw CaptureStoreError.writeFailed
        }
        CGImageDestinationAddImage(
            destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CaptureStoreError.writeFailed }
        return data as Data
    }
}
