//
//  MediaFileStore.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

actor MediaFileStore {
    private static let folder = "Media"

    nonisolated func url(forRelativePath path: String) -> URL {
        URL.applicationSupportDirectory.appending(path: path)
    }

    func store(_ data: Data, fileExtension: String) throws -> String {
        let relativePath = try makeRelativePath(fileExtension: fileExtension)
        try data.write(to: url(forRelativePath: relativePath), options: .atomic)
        return relativePath
    }

    func adopt(movieAt movieURL: URL) throws -> String {
        let relativePath = try makeRelativePath(fileExtension: "mov")
        try FileManager.default.moveItem(at: movieURL, to: url(forRelativePath: relativePath))
        return relativePath
    }

    private func makeRelativePath(fileExtension: String) throws -> String {
        let root = url(forRelativePath: Self.folder)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return "\(Self.folder)/\(UUID().uuidString).\(fileExtension)"
    }
}
