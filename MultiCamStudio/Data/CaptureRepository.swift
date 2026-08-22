//
//  CaptureRepository.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import SwiftData

@MainActor
final class CaptureRepository: CaptureStore {
    nonisolated let changes: AsyncStream<[Capture]>

    private let container: ModelContainer?
    private let mediaFileStore = MediaFileStore()
    private let posterService: any MoviePosterService
    private nonisolated let changeContinuation: AsyncStream<[Capture]>.Continuation

    init(posterService: any MoviePosterService) {
        self.posterService = posterService
        container = try? ModelContainer(
            for: CaptureRecord.self,
            BackMediaRecord.self,
            FrontMediaRecord.self
        )
        let (stream, continuation) = AsyncStream.makeStream(
            of: [Capture].self,
            bufferingPolicy: .bufferingNewest(1)
        )
        changes = stream
        changeContinuation = continuation
    }

    func loadCaptures() throws -> [Capture] {
        guard let context = container?.mainContext else { throw CaptureStoreError.storeUnavailable }
        var descriptor = FetchDescriptor<CaptureRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.relationshipKeyPathsForPrefetching = [\.back, \.front]
        return try context.fetch(descriptor).compactMap(capture(from:))
    }

    func savePhotoCapture(back: CapturedPhoto, lens: CaptureLens) async throws {
        let relativePath = try await mediaFileStore.store(back.data, fileExtension: back.fileExtension)
        try insert(
            media: BackMediaRecord(
                lensRawValue: lens.rawValue,
                relativePath: relativePath,
                posterRelativePath: nil,
                duration: nil
            )
        )
    }

    func saveMovieCapture(back: CapturedMovie, lens: CaptureLens) async throws {
        let relativePath = try await mediaFileStore.adopt(movieAt: back.url)
        let movieURL = mediaFileStore.url(forRelativePath: relativePath)
        var posterRelativePath: String?
        if let poster = try? await posterService.posterJPEG(for: movieURL) {
            posterRelativePath = try? await mediaFileStore.store(poster, fileExtension: "jpg")
        }
        try insert(
            media: BackMediaRecord(
                lensRawValue: lens.rawValue,
                relativePath: relativePath,
                posterRelativePath: posterRelativePath,
                duration: back.duration
            )
        )
    }

    private func insert(media: BackMediaRecord) throws {
        guard let context = container?.mainContext else { throw CaptureStoreError.storeUnavailable }
        let record = CaptureRecord(id: UUID(), createdAt: .now)
        context.insert(record)
        context.insert(media)
        record.back = media
        try context.save()
        changeContinuation.yield(try loadCaptures())
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
                duration: back.duration
            ),
            front: record.front.map { front in
                media(
                    lensRawValue: front.lensRawValue,
                    path: front.relativePath,
                    poster: front.posterRelativePath,
                    duration: front.duration
                )
            }
        )
    }

    private func media(
        lensRawValue: String,
        path: String,
        poster: String?,
        duration: TimeInterval?
    ) -> CaptureMedia {
        CaptureMedia(
            lens: CaptureLens(rawValue: lensRawValue) ?? .back,
            url: mediaFileStore.url(forRelativePath: path),
            posterURL: poster.map(mediaFileStore.url(forRelativePath:)),
            duration: duration
        )
    }
}
