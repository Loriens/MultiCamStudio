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
    private let posterService: any MoviePosterService
    private nonisolated let changeContinuation: AsyncStream<[Capture]>.Continuation

    init(posterService: any MoviePosterService, container: ModelContainer?) {
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
        let backPath = try await mediaFileStore.store(
            photos.back.data,
            fileExtension: photos.back.fileExtension
        )
        var frontPath: String?
        if let front = photos.front {
            frontPath = try? await mediaFileStore.store(front.data, fileExtension: front.fileExtension)
        }
        try await insert(
            back: BackMediaRecord(
                lensRawValue: CaptureLens.back.rawValue,
                relativePath: backPath,
                posterRelativePath: nil,
                startOffset: 0,
                duration: nil
            ),
            front: frontPath.map { path in
                FrontMediaRecord(
                    lensRawValue: CaptureLens.front.rawValue,
                    relativePath: path,
                    posterRelativePath: nil,
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

    private func adopt(_ movie: CapturedMovie) async throws -> (path: String, posterPath: String?) {
        let path = try await mediaFileStore.adopt(movieAt: movie.url)
        let movieURL = mediaFileStore.url(forRelativePath: path)
        var posterPath: String?
        if let poster = try? await posterService.posterJPEG(for: movieURL) {
            posterPath = try? await mediaFileStore.store(poster, fileExtension: "jpg")
        }
        return (path, posterPath)
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
