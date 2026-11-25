import SwiftUI

// MARK: - Frame timeline
//
// Horizontal, scrollable strip of frame thumbnails. Swipe to browse frames;
// hold a frame then drag left or right to reorder it. The gold marker sits on
// the selected thumbnail itself, so it stays aligned while scrolling.

struct FrameTimelineView: View {
    @ObservedObject var studio: StudioState
    var coachTarget: StudioCoachTarget?

    @State private var draggingIndex: Int?
    @State private var dropIndex: Int?
    @State private var dragOffset: CGFloat = 0

    private let cellWidth: CGFloat = 82 // 76pt thumbnail + 6pt spacing

    private func beginReorder(at index: Int) {
        guard !studio.isMultiSelecting else { return }
        draggingIndex = index
        dropIndex = index
        Haptics.light()
    }

    private func updateReorder(at index: Int, translation: CGFloat) {
        guard !studio.isMultiSelecting, draggingIndex == index else { return }
        dragOffset = translation
        let steps = Int((translation / cellWidth).rounded())
        let lastIndex = studio.project.frames.count - 1
        let target = max(0, min(lastIndex, index + steps))
        if target != dropIndex {
            dropIndex = target
            Haptics.light()
        }
    }

    private func finishReorder(at index: Int) {
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

    private func reorderGesture(at index: Int) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    beginReorder(at: index)
                case .second(true, let drag?):
                    updateReorder(at: index, translation: drag.translation.width)
                default:
                    break
                }
            }
            .onEnded { value in
                guard case .second(true, _) = value else { return }
                finishReorder(at: index)
            }
    }

    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: true) {
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
                        // A plain swipe belongs to the ScrollView. Only after
                        // the long press succeeds does the drag take over for
                        // reordering, so more frames can always be scrolled to.
                        .gesture(reorderGesture(at: index))
                        .accessibilityLabel("Frame \(index + 1). Hold and drag to reorder.")
                    }
                }
                .padding(.horizontal, 2)
            }

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
        .coachSpotlight(active: coachTarget == .some(.timeline))
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
                let transform = PoseViewTransform(
                    canvasSize: size,
                    topMargin: 0,
                    bottomMargin: 0,
                    leftMargin: 0,
                    rightMargin: 0
                )
                context.stroke(
                    transform.transformedPath(StickmanKinematics.skeletonPath(for: pose)),
                    with: .color(pose.color),
                    style: StrokeStyle(
                        lineWidth: max(2.5, pose.thickness * transform.scale),
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                let head = StickmanKinematics.headCircle(for: pose)
                let center = transform.toCanvas(head.center)
                let radius = head.radius * transform.scale
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )),
                    with: .color(pose.color)
                )
            }
            .frame(width: 76, height: 78)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isMultiSelected
                            ? Color(hex: 0x4C8DFF).opacity(0.3)
                            : Color.white.opacity(isSelected ? 0.16 : 0.06)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isMultiSelected
                            ? Color(hex: 0x4C8DFF)
                            : (isSelected
                                ? Color(hex: 0xF5C451).opacity(0.9)
                                : Color.white.opacity(0.12)),
                        lineWidth: (isMultiSelected || isSelected) ? 2.5 : 1
                    )
            )
        }
    }
}
