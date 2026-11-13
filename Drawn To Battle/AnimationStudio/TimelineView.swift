import SwiftUI

// MARK: - Frame timeline

/// Horizontal strip of frame thumbnails (management buttons live in the row
/// beside it in the studio layout).
struct FrameTimelineView: View {
    @ObservedObject var studio: StudioState

    var body: some View {
        HStack(spacing: 8) {
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
                .padding(.vertical, 3)
                .padding(.horizontal, 2)
            }

            Text("\(studio.selectedIndex + 1)/\(studio.project.frames.count)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .frame(minWidth: 34)
        }
    }
}

private struct FrameThumbnail: View {
    let pose: StickmanPose
    let isSelected: Bool
    let index: Int

    var body: some View {
        VStack(spacing: 2) {
            Canvas { context, size in
                // Scale the pose to fit the thumbnail.
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
                    .stroke(isSelected ? Color(hex: 0xF5C451) : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}
