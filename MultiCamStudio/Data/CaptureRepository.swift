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
    private let mediaFileStore: MediaFileStore
    private let reader: CaptureReader?
    private let posterService: any PosterService
    private nonisolated let changeContinuation: AsyncStream<[Capture]>.Continuation

    init(posterService: any PosterService, container: ModelContainer?) {
        self.posterService = posterService
        self.container = container
        let store = MediaFileStore()
        mediaFileStore = store
        reader = container.map { CaptureReader(container: $0, mediaFileStore: store) }
        let (stream, continuation) = AsyncStream.makeStream(
            of: [Capture].self,
            bufferingPolicy: .bufferingNewest(1)
        )
        changes = stream
        changeContinuation = continuation
    }

    func loadCaptures() async throws -> [Capture] {
        guard let reader else { throw CaptureStoreError.storeUnavailable }
        return try await reader.captures()
    }

    func savePhotoCapture(_ photos: CapturedPhotoPair) async throws {
        let back = try await adopt(photos.back)
        var front: (path: String, posterPath: String?)?
        if let photo = photos.front {
            front = try? await adopt(photo)
        }
        try await insert(
            back: BackMediaRecord(
                lensRawValue: CaptureLens.back.rawValue,
                relativePath: back.path,
                posterRelativePath: back.posterPath,
                startOffset: 0,
                duration: nil
            ),
            front: front.map { stored in
                FrontMediaRecord(
                    lensRawValue: CaptureLens.front.rawValue,
                    relativePath: stored.path,
                    posterRelativePath: stored.posterPath,
                    startOffset: 0,
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
        try await insert(
            back: BackMediaRecord(
                lensRawValue: CaptureLens.back.rawValue,
                relativePath: back.path,
                posterRelativePath: back.posterPath,
                startOffset: movies.back.startOffset,
                duration: movies.back.duration
            ),
            front: front.map { stored in
                FrontMediaRecord(
                    lensRawValue: CaptureLens.front.rawValue,
                    relativePath: stored.path,
                    posterRelativePath: stored.posterPath,
                    startOffset: movies.front?.startOffset ?? 0,
                    duration: movies.front?.duration
                )
            }
        )
    }

    func backfillMissingPosters() async {
        guard let context = container?.mainContext, let reader else { return }

        let back =
            ((try? context.fetch(FetchDescriptor<BackMediaRecord>())) ?? [])
            .filter { $0.posterRelativePath == nil }
        let front =
            ((try? context.fetch(FetchDescriptor<FrontMediaRecord>())) ?? [])
            .filter { $0.posterRelativePath == nil }
        guard !back.isEmpty || !front.isEmpty else { return }

        for record in back {
            record.posterRelativePath = await generatedPosterPath(
                forRelativePath: record.relativePath,
                isVideo: record.duration != nil
            )
        }
        for record in front {
            record.posterRelativePath = await generatedPosterPath(
                forRelativePath: record.relativePath,
                isVideo: record.duration != nil
            )
        }

        try? context.save()
        guard let refreshed = try? await reader.captures() else { return }
        changeContinuation.yield(refreshed)
    }

    private func adopt(_ movie: CapturedMovie) async throws -> (path: String, posterPath: String?) {
        let path = try await mediaFileStore.adopt(movieAt: movie.url)
        return (path, await generatedPosterPath(forRelativePath: path, isVideo: true))
    }

    private func adopt(_ photo: CapturedPhoto) async throws -> (path: String, posterPath: String?) {
        let path = try await mediaFileStore.store(photo.data, fileExtension: photo.fileExtension)
        return (path, await generatedPosterPath(forRelativePath: path, isVideo: false))
    }

    private func generatedPosterPath(forRelativePath path: String, isVideo: Bool) async -> String? {
        let url = mediaFileStore.url(forRelativePath: path)
        let poster =
            isVideo
            ? try? await posterService.posterJPEG(for: url)
            : try? await posterService.posterJPEG(forPhotoAt: url)
        guard let poster else { return nil }
        return try? await mediaFileStore.store(poster, fileExtension: "jpg")
    }

    private func insert(back: BackMediaRecord, front: FrontMediaRecord?) async throws {
        guard let context = container?.mainContext, let reader else {
            throw CaptureStoreError.storeUnavailable
        }
        let record = CaptureRecord(id: UUID(), createdAt: .now)
        context.insert(record)
        context.insert(back)
        record.back = back
        if let front {
            context.insert(front)
            record.front = front
        }
        try context.save()
        let refreshed = try await reader.captures()
        changeContinuation.yield(refreshed)
    }
}
