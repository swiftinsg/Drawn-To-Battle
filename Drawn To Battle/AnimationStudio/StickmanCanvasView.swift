import SwiftUI

// MARK: - Canvas rendering

struct StickmanCanvasView: View {
    /// The pose being edited (live-updated during drags).
    let pose: StickmanPose
    /// Currently selected bone (highlighted handle).
    @Binding var selectedBone: Bone?
    /// Called with (bone, new world angle in radians) while rotating.
    var onRotate: (Bone, CGFloat) -> Void
    /// Called with the new root position while moving.
    var onMove: (CGPoint) -> Void
    /// Show editing handles (false during playback).
    var editingHandles: Bool
    /// Height of the bottom overlay panel, so floor + figure sit above it.
    var bottomInset: CGFloat = 0
    /// Width reserved by a floating inspector on the right.
    var rightInset: CGFloat = 0
    /// Height reserved by the top bar.
    var topInset: CGFloat = 0
    /// Faded ghosts of previous frames (onion skinning), nearest first.
    var ghostPoses: [StickmanPose] = []

    @State private var dragBone: Bone?

    var body: some View {
        GeometryReader { geo in
            let t = PoseViewTransform(
                canvasSize: geo.size,
                topMargin: topInset,
                bottomMargin: bottomInset + 26,
                rightMargin: rightInset
            )
            ZStack {
                // Paper surface: the canvas is a light "sheet of paper" with a
                // dark sketch border, surrounded by dark studio chrome.
                PaperSurface()

                Canvas { context, size in
                    // Floor line for readability.
                    var floor = Path()
                    floor.move(to: CGPoint(x: 20, y: size.height - bottomInset - 14))
                    floor.addLine(to: CGPoint(x: size.width - rightInset - 20, y: size.height - bottomInset - 14))
                    context.stroke(
                        floor,
                        with: .color(Color(hex: 0x1A1A1E).opacity(0.28)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
                    )

                    // Onion-skin ghosts of previous frames.
                    for (ghostIndex, ghost) in ghostPoses.enumerated() {
                        let alpha = 0.22 - Double(ghostIndex) * 0.09
                        guard alpha > 0 else { continue }
                        let ghostPath = t.transformedPath(StickmanKinematics.skeletonPath(for: ghost))
                        context.stroke(
                            ghostPath,
                            with: .color(Color(hex: 0x1A1A1E).opacity(alpha)),
                            style: StrokeStyle(lineWidth: ghost.thickness * t.scale, lineCap: .round, lineJoin: .round)
                        )
                        let ghostHead = StickmanKinematics.headCircle(for: ghost)
                        let ghc = t.toCanvas(ghostHead.center)
                        let ghr = ghostHead.radius * t.scale
                        context.fill(
                            Path(ellipseIn: CGRect(x: ghc.x - ghr, y: ghc.y - ghr, width: ghr * 2, height: ghr * 2)),
                            with: .color(Color(hex: 0x1A1A1E).opacity(alpha))
                        )
                    }

                    // Skeleton (torso/limbs drawn first so the filled head can
                    // cover any part of the torso stroke that would poke into
                    // the head circle).
                    let path = t.transformedPath(StickmanKinematics.skeletonPath(for: pose))
                    context.stroke(
                        path,
                        with: .color(pose.color),
                        style: StrokeStyle(lineWidth: pose.thickness * t.scale, lineCap: .round, lineJoin: .round)
                    )

                    // Head: fully filled with the body colour, on top of the torso.
                    let head = StickmanKinematics.headCircle(for: pose)
                    let center = t.toCanvas(head.center)
                    let radius = head.radius * t.scale
                    let headRect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.fill(Path(ellipseIn: headRect), with: .color(pose.color))
                }
                .contentShape(Rectangle())

                if editingHandles {
                    JointHandles(pose: pose, transform: t, selectedBone: selectedBone)
                        .allowsHitTesting(false)
                }
            }
            .gesture(editGesture(t))
        }
    }

    // MARK: Gestures

    /// Drag near a joint handle rotates that bone; drag elsewhere moves the whole figure.
    private func editGesture(_ t: PoseViewTransform) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard editingHandles else { return }
                let posePoint = t.toPose(value.location)
                let startPosePoint = t.toPose(value.startLocation)

                if dragBone == nil {
                    // Decide at drag start: rotate if we grabbed near a handle.
                    dragBone = nearestRotatableBone(to: startPosePoint, scale: t.scale)
                }

                guard let bone = dragBone else {
                    // Move the whole figure (hip follows the finger).
                    onMove(posePoint)
                    return
                }
                let angle = worldAngle(of: bone, dragPoint: posePoint)
                onRotate(bone, angle)
            }
            .onEnded { _ in
                dragBone = nil
            }
    }

    private func nearestRotatableBone(to p: CGPoint, scale: CGFloat) -> Bone? {
        let joints = StickmanKinematics.resolve(pose)
        var best: (Bone, CGFloat)?
        for bone in Bone.rotatable {
            guard let handle = handleAnchor(for: bone, joints: joints) else { continue }
            let d = hypot(p.x - handle.x, p.y - handle.y)
            if best == nil || d < best!.1 {
                best = (bone, d)
            }
        }
        guard let hit = best, hit.1 < 60 / max(scale, 0.01) else { return nil }
        selectedBone = hit.0
        return hit.0
    }

    /// Angle from the bone's pivot to the drag point (pose space; uniform scale
    /// preserves angles, so no extra correction is needed).
    private func worldAngle(of bone: Bone, dragPoint p: CGPoint) -> CGFloat {
        let joints = StickmanKinematics.resolve(pose)
        guard let pivot = pivotAnchor(for: bone, joints: joints) else { return 0 }
        return atan2(p.y - pivot.y, p.x - pivot.x)
    }

    private func handleAnchor(for bone: Bone, joints: [JointPoint: CGPoint]) -> CGPoint? {
        switch bone {
        case .torso: return joints[.neck]
        case .head: return StickmanKinematics.headCircle(for: pose).center
        case .leftUpperArm: return joints[.leftElbow]
        case .leftForearm: return joints[.leftHand]
        case .rightUpperArm: return joints[.rightElbow]
        case .rightForearm: return joints[.rightHand]
        case .leftThigh: return joints[.leftKnee]
        case .leftShin: return joints[.leftFoot]
        case .rightThigh: return joints[.rightKnee]
        case .rightShin: return joints[.rightFoot]
        }
    }

    private func pivotAnchor(for bone: Bone, joints: [JointPoint: CGPoint]) -> CGPoint? {
        switch bone {
        case .torso: return joints[.hip]
        case .head: return joints[.neck]
        case .leftUpperArm, .rightUpperArm: return joints[.leftShoulder]
        case .leftForearm: return joints[.leftElbow]
        case .rightForearm: return joints[.rightElbow]
        case .leftThigh, .rightThigh: return joints[.hip]
        case .leftShin: return joints[.leftKnee]
        case .rightShin: return joints[.rightKnee]
        }
    }
}

// MARK: - Paper surface

/// The canvas zone: a light paper sheet with a dark sketch border,
/// sitting on dark studio chrome around it.
private struct PaperSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: 0xF7F7F7))
            .shadow(color: Color.black.opacity(0.18), radius: 12, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.black.opacity(0.10), lineWidth: 2)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Joint handle dots

private struct JointHandles: View {
    let pose: StickmanPose
    let transform: PoseViewTransform
    let selectedBone: Bone?

    var body: some View {
        Canvas { context, _ in
            let joints = StickmanKinematics.resolve(pose)

            func drawHandle(_ joint: JointPoint, for bone: Bone) {
                guard let p = joints[joint] else { return }
                let c = transform.toCanvas(p)
                let isSelected = selectedBone == bone
                if isSelected {
                    // Yellow dot with a white ring for the selected bone.
                    let ring = CGRect(x: c.x - 8, y: c.y - 8, width: 16, height: 16)
                    context.stroke(
                        Path(ellipseIn: ring),
                        with: .color(Color(hex: 0xF5C451)),
                        lineWidth: 1.5
                    )
                    let dot = CGRect(x: c.x - 5.5, y: c.y - 5.5, width: 11, height: 11)
                    context.fill(Path(ellipseIn: dot), with: .color(Color(hex: 0xF5C451)))
                } else {
                    // Small subtle dot for other joints.
                    let dot = CGRect(x: c.x - 3.5, y: c.y - 3.5, width: 7, height: 7)
                    context.fill(Path(ellipseIn: dot), with: .color(Color(hex: 0x1A1A1E).opacity(0.55)))
                }
            }

            drawHandle(.neck, for: .torso)
            // Head handle sits at the head-circle centre (inside the head,
            // so it does not look like a bun on top).
            let headCenter = StickmanKinematics.headCircle(for: pose).center
            let hc = transform.toCanvas(headCenter)
            if selectedBone == .head {
                let ring = CGRect(x: hc.x - 8, y: hc.y - 8, width: 16, height: 16)
                context.stroke(Path(ellipseIn: ring), with: .color(Color(hex: 0xF5C451)), lineWidth: 1.5)
                let dot = CGRect(x: hc.x - 5.5, y: hc.y - 5.5, width: 11, height: 11)
                context.fill(Path(ellipseIn: dot), with: .color(Color(hex: 0xF5C451)))
            } else {
                let dot = CGRect(x: hc.x - 3.5, y: hc.y - 3.5, width: 7, height: 7)
                context.fill(Path(ellipseIn: dot), with: .color(Color(hex: 0x1A1A1E).opacity(0.55)))
            }
            drawHandle(.leftElbow, for: .leftUpperArm)
            drawHandle(.leftHand, for: .leftForearm)
            drawHandle(.rightElbow, for: .rightUpperArm)
            drawHandle(.rightHand, for: .rightForearm)
            drawHandle(.leftKnee, for: .leftThigh)
            drawHandle(.leftFoot, for: .leftShin)
            drawHandle(.rightKnee, for: .rightThigh)
            drawHandle(.rightFoot, for: .rightShin)
        }
    }
}
