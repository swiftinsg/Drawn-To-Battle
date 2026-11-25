import SwiftUI

// MARK: - Shared visual tokens
//
// Pure presentation helpers. No game state, layout geometry, or actions live
// here, so screens can be polished without changing how anything works.

enum AppStyle {
    static let base = Color(hex: 0x0C0D12)
    static let surface = Color(hex: 0x14161E)
    static let raised = Color(hex: 0x171920)
    static let gold = Color(hex: 0xF5C451)
    static let danger = Color(hex: 0xE86A6A)
    static let success = Color(hex: 0x5FBF6E)

    static let hairline = Color.white.opacity(0.12)
    static let softHairline = Color.white.opacity(0.08)
    static let scrim = Color.black.opacity(0.78)
    static let tutorialScrim = Color.black.opacity(0.85)

    static let smallCorner: CGFloat = 10
    static let mediumCorner: CGFloat = 14
    static let largeCorner: CGFloat = 18
}

private struct AppEyebrowModifier: ViewModifier {
    let size: CGFloat
    let tracking: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .tracking(tracking)
            .foregroundStyle(AppStyle.gold.opacity(0.8))
    }
}

extension View {
    /// One consistent label style for section headers and capsule headings.
    func appEyebrow(size: CGFloat = 10, tracking: CGFloat = 1.4) -> some View {
        modifier(AppEyebrowModifier(size: size, tracking: tracking))
    }

    /// One consistent dialog/card surface. The accent stroke is optional.
    func appModalCard(
        accent: Color? = nil,
        cornerRadius: CGFloat = AppStyle.largeCorner
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppStyle.raised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accent?.opacity(0.45) ?? AppStyle.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
    }
}
