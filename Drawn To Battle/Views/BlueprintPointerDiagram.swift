import SwiftUI
import Foundation

// MARK: - Pointer diagram
//
// A small stickman with animated gold arrows pointing at the joint a blueprint
// needs most. Used inside the per-blueprint tutorial so it literally points at
// the body part the player should animate.

struct BlueprintPointerDiagram: View {
    let focus: BlueprintFocus
    @State private var pulse = false

    var body: some View {
        ZStack {
            figurePath()
                .stroke(Color.white.opacity(0.78),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))

            ForEach(focus.points, id: \.x) { point in
                pointer(at: point)
            }
        }
        .frame(width: 200, height: 250)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private func pointer(at point: CGPoint) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xF5C451).opacity(0.22))
                .frame(width: 22, height: 22)
                .position(point)

            Circle()
                .stroke(Color(hex: 0xF5C451), lineWidth: 3)
                .frame(width: 32, height: 32)
                .position(point)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .opacity(pulse ? 1.0 : 0.55)

            arrowPath(to: point)
                .stroke(Color(hex: 0xF5C451),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }

    private func figurePath() -> Path {
        var path = Path()
        // Head.
        path.addEllipse(in: CGRect(x: 82, y: 20, width: 36, height: 36))
        // Torso.
        path.move(to: CGPoint(x: 100, y: 56))
        path.addLine(to: CGPoint(x: 100, y: 140))
        // Arms.
        path.move(to: CGPoint(x: 100, y: 68))
        path.addLine(to: CGPoint(x: 128, y: 88))
        path.addLine(to: CGPoint(x: 146, y: 126))
        path.move(to: CGPoint(x: 100, y: 68))
        path.addLine(to: CGPoint(x: 72, y: 88))
        path.addLine(to: CGPoint(x: 54, y: 126))
        // Legs.
        path.move(to: CGPoint(x: 100, y: 140))
        path.addLine(to: CGPoint(x: 120, y: 168))
        path.addLine(to: CGPoint(x: 128, y: 238))
        path.move(to: CGPoint(x: 100, y: 140))
        path.addLine(to: CGPoint(x: 80, y: 168))
        path.addLine(to: CGPoint(x: 72, y: 238))
        return path
    }

    private func arrowPath(to point: CGPoint) -> Path {
        let dx: CGFloat = point.x >= 100 ? 30 : -30
        let tail = CGPoint(x: point.x + dx, y: point.y - 44)
        let angle = atan2(point.y - tail.y, point.x - tail.x)
        let head: CGFloat = 11

        var path = Path()
        path.move(to: tail)
        path.addLine(to: point)
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x + head * cos(angle + .pi - 0.45),
                                 y: point.y + head * sin(angle + .pi - 0.45)))
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x + head * cos(angle + .pi + 0.45),
                                 y: point.y + head * sin(angle + .pi + 0.45)))
        return path
    }
}
