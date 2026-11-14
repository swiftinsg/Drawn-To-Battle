import SwiftUI
import UIKit
import CoreText

enum DrawnToBattleTypography {
    // Rust Sport (Andriy Dykun) — free for personal and commercial use.
    // The TTF ships in the app bundle ("RustSport.ttf") and is registered
    // at runtime below — no Info.plist needed. Falls back gracefully
    // if the file is ever missing.
    static let rustFamilyName = "RustSport"

    /// Registers the bundled font once, on first use.
    private static let registerBundledFont: Void = {
        guard let url = Bundle.main.url(forResource: "RustSport", withExtension: "ttf") else { return }
        // true from the handler = ignore "already registered" errors.
        CTFontManagerRegisterFontURLs([url] as CFArray, .process, true) { _, _ in true }
    }()

    /// True if the Rust Sport font file is embedded in the bundle.
    static var rustFontAvailable: Bool {
        registerBundledFont
        return UIFont(name: rustFamilyName, size: 20) != nil
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
