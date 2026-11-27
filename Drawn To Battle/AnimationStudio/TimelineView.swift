import SwiftUI

// MARK: - Frame timeline
//
// Horizontal, scrollable strip of frame thumbnails. Tap a thumbnail to edit
// that frame; swipe the strip to browse frames. A long press picks a frame up
// and tapping another frame moves it there, without stealing touches from
// scrolling or selection.

struct FrameTimelineView: View {
    @ObservedObject var studio: StudioState
    var coachTarget: StudioCoachTarget?

    /// Drives only the decorative scroll rail; never affects frame editing.
    @State private var scrollMetrics = ScrollMetrics()
    /// Set by a long press. The next tap becomes the drop destination.
    @State private var reorderSourceIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 6) {
                        ForEach(Array(studio.project.frames.enumerated()), id: \.element.id) { index, frame in
                            FrameThumbnail(
                                pose: frame.pose,
                                isSelected: index == studio.selectedIndex,
                                isMultiSelected: studio.selectedFrameIDs.contains(frame.id)
                            )
                            .id(frame.id)
                            .overlay(alignment: .top) {
                                if !studio.isMultiSelecting,
                                   reorderSourceIndex == nil,
                                   index == studio.selectedIndex {
                                    Triangle()
                                        .fill(AppStyle.gold)
                                        .frame(width: 12, height: 8)
                                        .offset(y: -1)
                                        .allowsHitTesting(false)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        reorderSourceIndex == index
                                            ? Color(hex: 0x4FC3F7)
                                            : Color.clear,
                                        lineWidth: 3
                                    )
                                    .allowsHitTesting(false)
                            )
                            .onTapGesture {
                                handleTap(at: index, frameID: frame.id)
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.35)
                                    .onEnded { _ in
                                        guard !studio.isMultiSelecting else { return }
                                        reorderSourceIndex = index
                                        Haptics.light()
                                    }
                            )
                            .accessibilityLabel(
                                reorderSourceIndex == index
                                    ? "Frame \(index + 1) picked up. Tap another frame to move it."
                                    : "Frame \(index + 1). Tap to edit. Long press to move."
                            )
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
                .onChange(of: studio.selectedIndex) { _, newIndex in
                    guard studio.project.frames.indices.contains(newIndex) else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(studio.project.frames[newIndex].id, anchor: .center)
                    }
                }
            }

            scrollRail

            if reorderSourceIndex != nil {
                Text("TAP ANOTHER FRAME TO MOVE IT THERE")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(AppStyle.gold)
                    .padding(.top, 3)
            }
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
        .onChange(of: studio.project.frames.count) { _, _ in
            reorderSourceIndex = nil
        }
    }

    private func handleTap(at index: Int, frameID: UUID) {
        if let source = reorderSourceIndex {
            if source != index {
                studio.moveFrame(from: source, to: index)
            }
            reorderSourceIndex = nil
            Haptics.light()
            return
        }

        if studio.isMultiSelecting {
            studio.toggleFrameSelection(frameID)
        } else {
            studio.selectFrame(index)
        }
    }

    /// Always-visible scroll rail: dim track, gold thumb sized by the
    /// viewport/content ratio and moved by scroll progress. Pure decoration,
    /// it never handles touches.
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
