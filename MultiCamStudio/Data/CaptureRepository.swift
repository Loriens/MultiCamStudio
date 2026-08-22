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

    init(posterService: any MoviePosterService, container: ModelContainer?) {
        self.posterService = posterService
        self.container = container
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

    func savePhotoCapture(_ photos: CapturedPhotoPair) async throws {
        let backPath = try await mediaFileStore.store(
            photos.back.data,
            fileExtension: photos.back.fileExtension
        )
        var frontPath: String?
        if let front = photos.front {
            frontPath = try? await mediaFileStore.store(front.data, fileExtension: front.fileExtension)
        }
        try insert(
            back: BackMediaRecord(
                lensRawValue: CaptureLens.back.rawValue,
                relativePath: backPath,
                posterRelativePath: nil,
                duration: nil
            ),
            front: frontPath.map { path in
                FrontMediaRecord(
                    lensRawValue: CaptureLens.front.rawValue,
                    relativePath: path,
                    posterRelativePath: nil,
                    duration: nil
                )
            }
        )
    }

    func saveMovieCapture(_ movies: CapturedMoviePair) async throws {
        let back = try await adopt(movies.back)
        var front: (path: String, posterPath: String?)?
        if let movie = movies.front {
            front = try? await adopt(movie)
        }
        try insert(
            back: BackMediaRecord(
                lensRawValue: CaptureLens.back.rawValue,
                relativePath: back.path,
                posterRelativePath: back.posterPath,
                duration: movies.back.duration
            ),
            front: front.map { stored in
                FrontMediaRecord(
                    lensRawValue: CaptureLens.front.rawValue,
                    relativePath: stored.path,
                    posterRelativePath: stored.posterPath,
                    duration: movies.front?.duration
                )
            }
        )
    }

    private func adopt(_ movie: CapturedMovie) async throws -> (path: String, posterPath: String?) {
        let path = try await mediaFileStore.adopt(movieAt: movie.url)
        let movieURL = mediaFileStore.url(forRelativePath: path)
        var posterPath: String?
        if let poster = try? await posterService.posterJPEG(for: movieURL) {
            posterPath = try? await mediaFileStore.store(poster, fileExtension: "jpg")
        }
        return (path, posterPath)
    }

    private func insert(back: BackMediaRecord, front: FrontMediaRecord?) throws {
        guard let context = container?.mainContext else { throw CaptureStoreError.storeUnavailable }
        let record = CaptureRecord(id: UUID(), createdAt: .now)
        context.insert(record)
        context.insert(back)
        record.back = back
        if let front {
            context.insert(front)
            record.front = front
        }
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
