import SwiftUI

// MARK: - Hand-drawn chrome
//
// The game's art is hand-drawn, so the UI chrome around it should feel
// drawn too: wobbly marker-style borders, sticker depth, squashy press
// feedback and a slow idle bob.

/// A rectangle drawn like a marker: slightly wobbly edges and corners,
/// stable for a given seed. Two instances with the same seed trace the
/// exact same line, so fill and stroke line up.
/// (Randomness comes from the shared SeededRandom in BattleView.swift.)
struct SketchyRect: Shape {
    var seed: UInt64 = 7
    /// Wobble amplitude in points.
    var wobble: CGFloat = 2.2

    func path(in rect: CGRect) -> Path {
        var rng = SeededRandom(seed: seed)
        let amp = min(wobble, min(rect.width, rect.height) * 0.07)
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY),
        ]
        func jitter(_ p: CGPoint, _ rng: inout SeededRandom, scale: CGFloat = 1) -> CGPoint {
            CGPoint(x: p.x + (rng.next() * 2 - 1) * amp * scale,
                    y: p.y + (rng.next() * 2 - 1) * amp * scale)
        }

        var path = Path()
        path.move(to: jitter(corners[0], &rng, scale: 0.7))
        for i in 0..<4 {
            let start = corners[i]
            let end = corners[(i + 1) % 4]
            let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            path.addQuadCurve(to: jitter(end, &rng, scale: 0.7),
                              control: jitter(mid, &rng))
        }
        path.closeSubpath()
        return path
    }
}

/// Press feedback for sticker-style buttons: squash down and tilt a
/// touch, springing back on release.
struct SquashButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .rotationEffect(.degrees(configuration.isPressed ? -1.2 : 0))
            .animation(.spring(response: 0.26, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Slow idle bob for hero stickers — the drawing feels alive.
struct StickerBob: ViewModifier {
    var lift: CGFloat = 4
    @State private var up = false

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -lift : 2)
            .scaleEffect(up ? 1.025 : 1)
            .animation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true), value: up)
            .onAppear { up = true }
    }
}

extension View {
    /// Sticker depth: the art sits on the page instead of floating in a corner.
    func stickerShadow() -> some View {
        shadow(color: .black.opacity(0.45), radius: 9, y: 5)
    }
}
