//
//  MovieRecordingDelegate.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import AVFoundation
import Foundation

nonisolated final class MovieRecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    let results: AsyncStream<Result<URL, Error>>

    private let continuation: AsyncStream<Result<URL, Error>>.Continuation

    override init() {
        let (stream, continuation) = AsyncStream.makeStream(
            of: Result<URL, Error>.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        results = stream
        self.continuation = continuation
        super.init()
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error {
            continuation.yield(.failure(error))
        } else {
            continuation.yield(.success(outputFileURL))
        }
        continuation.finish()
    }
}
