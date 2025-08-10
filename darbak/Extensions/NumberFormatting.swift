//
//  NumberFormatting.swift
//  darbak
//
//  Created by Assistant on ${DATE}
//

import Foundation

// MARK: - Global Number Formatting
extension NumberFormatter {
    static let englishFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension Int {
    var englishFormatted: String {
        return NumberFormatter.englishFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var englishFormatted: String {
        return NumberFormatter.englishFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Float {
    var englishFormatted: String {
        return NumberFormatter.englishFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
