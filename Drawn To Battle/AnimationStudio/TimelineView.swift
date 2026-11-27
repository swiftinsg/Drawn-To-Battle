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
    /// Drives only the decorative scroll rail; never affects frame editing.
    @State private var scrollMetrics = ScrollMetrics()

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

    var body: some View {
        VStack(spacing: 0) {
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
                        // Separate simultaneous recognizers kept taps reliable
                        // while still allowing a held frame to be reordered.
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.35)
                                .onEnded { _ in
                                    guard !studio.isMultiSelecting else { return }
                                    beginReorder(at: index)
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard !studio.isMultiSelecting, draggingIndex == index else { return }
                                    updateReorder(at: index, translation: value.translation.width)
                                }
                                .onEnded { _ in
                                    guard draggingIndex == index else { return }
                                    finishReorder(at: index)
                                }
                        )
                        .accessibilityLabel("Frame \(index + 1). Hold and drag to reorder.")
                    }
                }
                .padding(.horizontal, 2)
            }
            .onScrollGeometryChange(for: ScrollMetrics.self) { geometry in
                let contentWidth = geometry.contentSize.width
                let visibleWidth = geometry.bounds.width
                let overflow = max(0, contentWidth - visibleWidth)
                return ScrollMetrics(
                    progress: overflow > 0 ? min(1, max(0, geometry.contentOffset.x / overflow)) : 0,
                    thumbRatio: contentWidth > 0 ? min(1, visibleWidth / contentWidth) : 1
                )
            } action: { _, metrics in
                scrollMetrics = metrics
            }

            scrollRail
        }
        .padding(.horizontal, 12)
        .padding(.top, 1)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.smallCorner)
                .fill(AppStyle.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.smallCorner)
                        .stroke(AppStyle.hairline, lineWidth: 1)
                )
        )
        .coachSpotlight(active: coachTarget == .some(.timeline))
    }

    /// Always-visible scroll rail: dim track, gold thumb sized by the
    /// viewport/content ratio and moved by scroll progress. Pure decoration —
    /// it never handles touches, so frame reordering is untouched.
    private var scrollRail: some View {
        GeometryReader { rail in
            let trackWidth = rail.size.width
            let thumbWidth = max(44, min(trackWidth, trackWidth * scrollMetrics.thumbRatio))
            let thumbX = (trackWidth - thumbWidth) * scrollMetrics.progress
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                Capsule()
                    .fill(AppStyle.gold)
                    .frame(width: thumbWidth)
                    .offset(x: thumbX)
                    .shadow(color: AppStyle.gold.opacity(0.4), radius: 6, y: 0)
            }
        }
        .frame(height: 7)
        .padding(.top, 2)
        .allowsHitTesting(false)
    }
}

private struct ScrollMetrics: Equatable {
    var progress: CGFloat = 0
    var thumbRatio: CGFloat = 1
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
                                ? AppStyle.gold
                                : Color.white.opacity(0.12)),
                        lineWidth: isSelected ? 3 : (isMultiSelected ? 2.5 : 1)
                    )
            )
        }
    }
}
