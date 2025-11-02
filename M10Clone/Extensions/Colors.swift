//
//  Colors.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct AppColors {
    // Primary M10 purple color
    static let primary = Color(hex: "7B3FF2")
    static let primaryLight = Color(hex: "9D6FF5")
    static let primaryDark = Color(hex: "5E2FBF")

    // Secondary colors
    static let secondary = Color(hex: "A855F7")
    static let accent = Color(hex: "C084FC")

    // Background colors
    static let background = Color(hex: "F8F9FA")
    static let cardBackground = Color.white
    static let darkBackground = Color(hex: "1A1A2E")

    // Text colors
    static let textPrimary = Color(hex: "1F2937")
    static let textSecondary = Color(hex: "6B7280")
    static let textLight = Color.white

    // Chat bubble colors
    static let userBubble = Color(hex: "7B3FF2")
    static let aiBubble = Color(hex: "F3F4F6")

    // System colors
    static let success = Color(hex: "10B981")
    static let error = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
