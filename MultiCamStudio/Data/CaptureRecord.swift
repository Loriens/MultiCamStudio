//
//  CaptureRecord.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class CaptureRecord {
    @Attribute(.unique)
    var id: UUID
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BackMediaRecord.capture)
    var back: BackMediaRecord?

    @Relationship(deleteRule: .cascade, inverse: \FrontMediaRecord.capture)
    var front: FrontMediaRecord?

    init(id: UUID, createdAt: Date) {
        self.id = id
        self.createdAt = createdAt
    }
}
