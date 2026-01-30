import SwiftUI

struct Theme {
    // Primary "Comfortable Green"
    static let primary = Color(hex: "27AE60") // Nephritis Green - calm and professional
    static let secondary = Color(hex: "2ECC71") // Emerald - slightly brighter
    static let accent = Color(hex: "1ABC9C") // Turquoise - for variety
    
    // Backgrounds
    static let background = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "27AE60"), Color(hex: "2ECC71")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let subtleGradient = LinearGradient(
        colors: [Color(hex: "27AE60").opacity(0.1), Color(hex: "2ECC71").opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shadows
    static let shadowColor = Color(hex: "27AE60").opacity(0.3)
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
