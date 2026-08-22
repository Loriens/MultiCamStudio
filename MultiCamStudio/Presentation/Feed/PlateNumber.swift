//
//  PlateNumber.swift
//  MultiCamStudio
//
//  Created by Vladislav Markov on 22/08/2026.
//

import Foundation

enum PlateNumber {
    private static let numerals: [(value: Int, symbol: String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]

    static func title(for number: Int) -> String {
        guard number > 0 else { return "Plate" }
        var remainder = number
        var symbols = ""
        for numeral in numerals {
            while remainder >= numeral.value {
                symbols += numeral.symbol
                remainder -= numeral.value
            }
        }
        return "Plate \(symbols)"
    }
}
