import SwiftUI

// MARK: - Frame timeline
//
// Dedicated timeline strip below the canvas: horizontal scroll of frame
// thumbnails, a gold playhead triangle on the selected frame, and the
// FPS stepper. Kept visually distinct from the pose controls above it.

struct FrameTimelineView: View {
    @ObservedObject var studio: StudioState

    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(studio.project.frames.enumerated()), id: \.element.id) { index, frame in
                        FrameThumbnail(
                            pose: frame.pose,
                            isSelected: index == studio.selectedIndex,
                            index: index
                        )
                        .onTapGesture { studio.selectFrame(index) }
                        .contextMenu {
                            Button("Duplicate") { studio.duplicateFrame(at: index) }
                            Button("Delete", role: .destructive) { studio.deleteFrame(at: index) }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            Spacer()

            // Frame counter + hold time, like the reference's "Frame n of m holds 0.42 s".
            Text("FRAME \(studio.selectedIndex + 1) OF \(studio.project.frames.count) · HOLDS \(String(format: "%.2f", studio.currentFrameDuration)) S")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)

            // Timecode from the start of the project through the selected frame.
            Text(timecodeString(studio.currentFrameStartTime))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))

            // FPS stepper.
            Stepper("FPS \(studio.project.fps)", value: Binding(
                get: { studio.project.fps },
                set: { studio.project.fps = $0; studio.hasUnsavedChanges = true }
            ), in: 1...30)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))
                .tint(Color(hex: 0xF5C451))
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            ZStack {
                Color(hex: 0x14161E)
                // Gold playhead on the selected frame.
                if !studio.project.frames.isEmpty {
                    PlayheadMarker(index: studio.selectedIndex)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        )
    }
}

// MARK: - Playhead

/// Vertical gold triangle marking the selected frame, roughly aligned
/// above its thumbnail (the thumbnails are 42pt wide, 6pt apart, 2pt
/// padding, starting after the top-bar padding — approximate is fine).
struct PlayheadMarker: View {
    let index: Int

    /// Approximate x of the selected thumbnail: 2pt padding + N thumbnails
    /// of 42pt + 6pt spacing, center of the selected one.
    private var x: CGFloat {
        2 + CGFloat(index) * (42 + 6) + (42 + 6) / 2
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            Triangle()
                .fill(Color(hex: 0xF5C451))
                .frame(width: 12, height: 8)
                .position(x: x, y: 12)
                .zIndex(1)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Triangle shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// HH:MM:SS timecode.
private func timecodeString(_ seconds: TimeInterval) -> String {
    let s = Int(seconds.rounded())
    return String(format: "%02d:%02d:%02d", s / 3600, (s / 60) % 60, s % 60)
}

private struct FrameThumbnail: View {
    let pose: StickmanPose
    let isSelected: Bool
    let index: Int

    var body: some View {
        ZStack {
            // Frame number badge.
            Text("\(index + 1)")
                .font(.system(size: 7, weight: .black, design: .monospaced))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                .frame(width: 16, height: 14)
                .background(
                    isSelected
                        ? Color(hex: 0xF5C451)
                        : Color.white.opacity(0.08)
                )
                .clipShape(Capsule())
                .position(x: 5, y: 4)
                .allowsHitTesting(false)

            Canvas { context, size in
                var scaled = pose
                let thumbScale: CGFloat = 0.34
                scaled.scale = pose.scale * thumbScale
                scaled.thickness = max(2, pose.thickness * thumbScale * 1.6)
                scaled.root = CGPoint(x: size.width / 2, y: size.height * 0.84)

                context.stroke(
                    StickmanKinematics.skeletonPath(for: scaled),
                    with: .color(scaled.color),
                    style: StrokeStyle(lineWidth: scaled.thickness, lineCap: .round, lineJoin: .round)
                )
                let head = StickmanKinematics.headCircle(for: scaled)
                let headRect = CGRect(
                    x: head.center.x - head.radius,
                    y: head.center.y - head.radius,
                    width: head.radius * 2,
                    height: head.radius * 2
                )
                context.fill(Path(ellipseIn: headRect), with: .color(scaled.color))
            }
            .frame(width: 42, height: 48)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.white.opacity(isSelected ? 0.16 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        isSelected
                            ? Color(hex: 0xF5C451).opacity(0.9)
                            : Color.white.opacity(0.12),
                        lineWidth: isSelected ? 2.2 : 1
                    )
            )
        }
    }
}
