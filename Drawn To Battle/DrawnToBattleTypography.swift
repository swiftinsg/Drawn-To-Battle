import SwiftUI

enum DrawnToBattleTypography {
    // Rust Sport (Andriy Dykun) — free for personal and commercial use.
    // Add "RustSport.ttf" to the project and Info.plist's UIAppFonts
    // entry ("RustSport") to activate; falls back gracefully otherwise.
    static let rustFamilyName = "RustSport"

    /// True if the Rust Sport font file is embedded in the bundle.
    static var rustFontAvailable: Bool {
        UIFont(name: rustFamilyName, size: 20) != nil
    }

    static func display(_ size: CGFloat) -> Font {
        if rustFontAvailable {
            return .custom(rustFamilyName, size: size)
        }
        // Fallback until the font file is provided by the user.
        return .system(size: size, weight: .black, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
