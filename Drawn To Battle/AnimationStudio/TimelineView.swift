import SwiftUI

// MARK: - Frame timeline
//
// Horizontal strip of frame thumbnails. Hold a frame then drag left or right
// to reorder it. The gold marker sits on the selected thumbnail itself, so it
// stays aligned even after the strip has been scrolled.

struct FrameTimelineView: View {
    @ObservedObject var studio: StudioState

    @State private var draggingIndex: Int?
    @State private var dropIndex: Int?
    @State private var dragOffset: CGFloat = 0

    private let cellWidth: CGFloat = 48 // 42pt thumbnail + 6pt spacing

    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(studio.project.frames.enumerated()), id: \.element.id) { index, frame in
                        FrameThumbnail(
                            pose: frame.pose,
                            isSelected: index == studio.selectedIndex,
                            isMultiSelected: studio.selectedFrameIDs.contains(frame.id)
                        )
                        .overlay(alignment: .top) {
                            if !studio.isMultiSelecting && draggingIndex == nil && index == studio.selectedIndex {
                                Triangle()
                                    .fill(Color(hex: 0xF5C451))
                                    .frame(width: 12, height: 8)
                                    .offset(y: -1)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xF5C451), lineWidth: 2)
                                .opacity(dropIndex == index && draggingIndex != index ? 1 : 0)
                                .allowsHitTesting(false)
                        )
                        .scaleEffect(draggingIndex == index ? 1.12 : 1)
                        .offset(x: draggingIndex == index ? dragOffset : 0)
                        .zIndex(draggingIndex == index ? 10 : 0)
                        .onTapGesture {
                            if studio.isMultiSelecting {
                                studio.toggleFrameSelection(frame.id)
                            } else if draggingIndex == nil {
                                studio.selectFrame(index)
                            }
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.35)
                                .onEnded { _ in
                                    guard !studio.isMultiSelecting else { return }
                                    draggingIndex = index
                                    dropIndex = index
                                    Haptics.light()
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard !studio.isMultiSelecting, draggingIndex == index else { return }
                                    dragOffset = value.translation.width
                                    let steps = Int((value.translation.width / cellWidth).rounded())
                                    let target = max(0,
                                                     min(studio.project.frames.count - 1,
                                                         index + steps))
                                    if target != dropIndex {
                                        dropIndex = target
                                        Haptics.light()
                                    }
                                }
                                .onEnded { _ in
                                    guard draggingIndex == index else { return }
                                    if let target = dropIndex, target != index {
                                        studio.moveFrame(from: index, to: target)
                                    }
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        draggingIndex = nil
                                        dropIndex = nil
                                        dragOffset = 0
                                    }
                                }
                        )
                        .accessibilityLabel("Frame \(index + 1). Hold and drag to reorder.")
                    }
                }
                .padding(.horizontal, 2)
            }

            Spacer()

            // FPS stepper.
            Stepper("FPS \(studio.project.fps)", value: Binding(
                get: { studio.project.fps },
                set: { studio.project.fps = $0; studio.markProjectChanged() }
            ), in: 1...30)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))
                .tint(Color(hex: 0xF5C451))
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.top, 1)
        .padding(.bottom, 3)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0x14161E))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
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

private struct FrameThumbnail: View {
    let pose: StickmanPose
    let isSelected: Bool
    let isMultiSelected: Bool

    var body: some View {
        ZStack {
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
            .frame(width: 32, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        isMultiSelected
                            ? Color(hex: 0x4C8DFF).opacity(0.3)
                            : Color.white.opacity(isSelected ? 0.16 : 0.06)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        isMultiSelected
                            ? Color(hex: 0x4C8DFF)
                            : (isSelected
                                ? Color(hex: 0xF5C451).opacity(0.9)
                                : Color.white.opacity(0.12)),
                        lineWidth: (isMultiSelected || isSelected) ? 2.2 : 1
                    )
            )
        }
    }
}
