//
//  Colors.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct AppColors {
    // Primary colors from CSS
    static let primary = Color(hex: "1D2331") // icon/primary, text/primary-default
    static let brandPrimary = Color(hex: "03EDC3") // brand/primary
    
    // Secondary colors
    static let secondary = Color(hex: "8E9198") // text/secondary-default
    static let iconSecondary = Color(hex: "777B83") // icon/secondary
    
    // Background colors
    static let background = Color(hex: "FFFFFF") // surface/primary-default
    static let backgroundSecondary = Color(hex: "F3F4F4") // surface/secondary-default
    static let backgroundSecondaryPressed = Color(hex: "E9E9EB") // surface/secondary-pressed
    static let cardBackground = Color.white

    // Text colors
    static let textPrimary = Color(hex: "1D2331") // text/primary-default
    static let textSecondary = Color(hex: "8E9198") // text/secondary-default
    static let textLight = Color.white // text/invert
    static let colorPrimary = Color(hex: "14234B") // color.primary

    // Border colors
    static let borderPrimary = Color(hex: "1D2331") // boarder/primary
    
    // Brand colors
    static let brandAccent = Color(hex: "6946F7")
    
    // System colors
    static let success = Color(hex: "10B981")
    static let error = Color(hex: "FF3333") // icon/error
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
