//
//  FeedItem.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

struct FeedItem: Identifiable, Hashable {
    let capture: Capture
    let plateTitle: String

    var id: UUID { capture.id }
}
