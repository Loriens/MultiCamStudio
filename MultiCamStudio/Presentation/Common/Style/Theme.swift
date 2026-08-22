//
//  Theme.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import SwiftUI

enum Theme {
    static let surface = Color(red: 32 / 255, green: 31 / 255, blue: 29 / 255)
    static let raised = Color(red: 45 / 255, green: 43 / 255, blue: 43 / 255)
    static let stripe = Color(red: 58 / 255, green: 56 / 255, blue: 56 / 255)
    static let text = Color(red: 243 / 255, green: 242 / 255, blue: 242 / 255)

    static let divider = text.opacity(0.14)
    static let matEdge = text.opacity(0.16)
    static let border = text.opacity(0.22)
    static let textMuted = text.opacity(0.55)
    static let textSubdued = text.opacity(0.5)
    static let textFaint = text.opacity(0.4)

    static let space1: CGFloat = 4.6
    static let space2: CGFloat = 9.2
    static let space3: CGFloat = 13.8
    static let space4: CGFloat = 18.4
    static let space6: CGFloat = 27.6
    static let space8: CGFloat = 36.8

    static let radiusSmall: CGFloat = 2
    static let radiusMedium: CGFloat = 4
    static let radiusLarge: CGFloat = 7

    static let stripeBand: CGFloat = 9
}
