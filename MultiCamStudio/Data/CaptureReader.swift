//
//  CaptureReader.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import SwiftData

actor CaptureReader {
    private let container: ModelContainer
    private let mediaFileStore: MediaFileStore

    init(container: ModelContainer, mediaFileStore: MediaFileStore) {
        self.container = container
        self.mediaFileStore = mediaFileStore
    }

    func captures() throws -> [Capture] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.back, \.front]
        return try context.fetch(descriptor).compactMap(capture(from:))
    }

    private func capture(from record: CaptureRecord) -> Capture? {
        guard let back = record.back else { return nil }
        return Capture(
            id: record.id,
            createdAt: record.createdAt,
            back: media(
                lensRawValue: back.lensRawValue,
                path: back.relativePath,
                poster: back.posterRelativePath,
                startOffset: back.startOffset,
                duration: back.duration
            ),
            front: record.front.map { front in
                media(
                    lensRawValue: front.lensRawValue,
                    path: front.relativePath,
                    poster: front.posterRelativePath,
                    startOffset: front.startOffset,
                    duration: front.duration
                )
            }
        )
    }

    private func media(
        lensRawValue: String,
        path: String,
        poster: String?,
        startOffset: TimeInterval,
        duration: TimeInterval?
    ) -> CaptureMedia {
        CaptureMedia(
            lens: CaptureLens(rawValue: lensRawValue) ?? .back,
            url: mediaFileStore.url(forRelativePath: path),
            posterURL: poster.map(mediaFileStore.url(forRelativePath:)),
            startOffset: startOffset,
            duration: duration
        )
    }
}
