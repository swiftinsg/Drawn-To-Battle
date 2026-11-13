import SwiftUI

// MARK: - Animation Studio (main screen)

struct AnimationStudioView: View {
    @ObservedObject var studio: StudioState
    @State private var selectedBone: Bone?
    @State private var projectsBrowserShown = false
    @State private var nameEditorShown = false

    var onBack: (() -> Void)?

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            // Full-screen editing canvas with overlaid panels.
            StickmanCanvasView(
                pose: studio.currentFrame?.pose ?? StickmanPose(),
                selectedBone: $selectedBone,
                onRotate: handleRotate,
                onMove: { newRoot in
                    studio.updateCurrentPose { pose in
                        pose.root = CGPoint(
                            x: min(390, max(10, newRoot.x)),
                            y: min(505, max(30, newRoot.y))
                        )
                    }
                },
                editingHandles: !studio.isPlaying,
                bottomInset: bottomPanelHeight,
                ghostPoses: onionSkinGhosts
            )
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                // Top bar.
                HStack(spacing: 10) {
                    if let onBack {
                        StudioIconButton(systemImage: "chevron.left") { onBack() }
                    }
                    Button {
                        nameEditorShown = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(studio.project.name)
                                .font(DrawnToBattleTypography.display(17))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if studio.hasUnsavedChanges {
                        Circle()
                            .fill(Color(hex: 0xF5C451))
                            .frame(width: 7, height: 7)
                    }
                    StudioIconButton(systemImage: "square.and.arrow.down") { _ = try? studio.save() }
                    StudioIconButton(systemImage: "folder") { projectsBrowserShown = true }
                    StudioIconButton(systemImage: "plus.rectangle.on.rectangle") { studio.newProject() }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 4)

                Spacer()

                // Bottom panel: pose controls, timeline, playback.
                VStack(spacing: 6) {
                    PoseControls(
                        selectedBone: $selectedBone,
                        pose: studio.currentFrame?.pose ?? StickmanPose(),
                        onRotate: handleRotate,
                        onThickness: { value in
                            studio.updateCurrentPose { pose in pose.thickness = value }
                        },
                        onScale: { value in
                            studio.updateCurrentPose { pose in pose.scale = value }
                        },
                        onBodyRotation: { value in
                            studio.updateCurrentPose { pose in pose.bodyRotation = value }
                        },
                        onColor: { value in
                            studio.updateCurrentPose { pose in pose.colorARGB = value }
                        }
                    )

                    HStack(spacing: 10) {
                        StudioIconButton(systemImage: "backward.end.fill") { studio.selectFrame(0) }
                        if studio.isPlaying {
                            StudioIconButton(systemImage: "stop.fill", prominent: true) { studio.stop() }
                        } else {
                            StudioIconButton(systemImage: "play.fill", prominent: true) { studio.play() }
                        }
                        StudioIconButton(systemImage: "forward.end.fill") {
                            studio.selectFrame(studio.project.frames.count - 1)
                        }

                        // Frame management.
                        StudioIconButton(systemImage: "plus") { studio.addFrame() }
                        StudioIconButton(systemImage: "doc.on.doc") {
                            studio.duplicateFrame(at: studio.selectedIndex)
                        }
                        StudioIconButton(systemImage: "arrow.left.to.line") {
                            studio.moveFrame(from: studio.selectedIndex, to: 0)
                        }
                        StudioIconButton(systemImage: "arrow.right.to.line") {
                            studio.moveFrame(from: studio.selectedIndex, to: studio.project.frames.count - 1)
                        }
                        StudioIconButton(systemImage: "trash", tinted: Color(hex: 0xE86A6A)) {
                            studio.deleteFrame(at: studio.selectedIndex)
                        }

                        // Onion skinning toggle.
                        Button {
                            studio.onionSkin.toggle()
                        } label: {
                            Image(systemName: "square.on.square")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(studio.onionSkin ? AnyShapeStyle(.black) : AnyShapeStyle(Color.white.opacity(0.85)))
                                .frame(width: 30, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(studio.onionSkin ? Color(hex: 0xF5C451) : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)

                        // Playback speed toggle.
                        Button {
                            studio.cyclePlaybackSpeed()
                        } label: {
                            Text(speedLabel)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(studio.playbackSpeed == 1 ? Color.white.opacity(0.85) : Color(hex: 0xF5C451))
                                .frame(width: 34, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)

                        FrameTimelineView(studio: studio)
                    }

                    HStack(spacing: 10) {
                        Stepper(
                            "FPS \(studio.project.fps)",
                            value: Binding(
                                get: { studio.project.fps },
                                set: { studio.project.fps = $0; studio.hasUnsavedChanges = true }
                            ),
                            in: 1...30
                        )
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize()

                        Spacer()

                        Text("Drag a joint to rotate • drag elsewhere to move")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)
                .background(
                    RoundedTopCorners(radius: 18)
                        .fill(Color(hex: 0x14161E).opacity(0.97))
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onDisappear { studio.stop() }
        .sheet(isPresented: $projectsBrowserShown) {
            ProjectBrowserSheet(studio: studio)
        }
        .alert("Project name", isPresented: $nameEditorShown) {
            TextField("Name", text: Binding(
                get: { studio.project.name },
                set: { studio.project.name = $0; studio.hasUnsavedChanges = true }
            ))
            Button("OK") {}
        }
    }

    /// Approximate height of the overlaid bottom panel, used by the canvas
    /// to keep the figure and floor line above it.
    private var bottomPanelHeight: CGFloat { 150 }

    private var speedLabel: String {
        switch studio.playbackSpeed {
        case 2: return "2×"
        case 0.5: return "½×"
        default: return "1×"
        }
    }

    /// Up to two previous frames for onion skinning, nearest first.
    private var onionSkinGhosts: [StickmanPose] {
        guard studio.onionSkin else { return [] }
        let idx = studio.selectedIndex
        var ghosts: [StickmanPose] = []
        if idx - 1 >= 0, studio.project.frames.indices.contains(idx - 1) {
            ghosts.append(studio.project.frames[idx - 1].pose)
        }
        if idx - 2 >= 0, studio.project.frames.indices.contains(idx - 2) {
            ghosts.append(studio.project.frames[idx - 2].pose)
        }
        return ghosts
    }

    // MARK: Rotation conversion

    /// Convert a drag's world angle into the bone's stored relative angle.
    private func handleRotate(bone: Bone, worldDragAngle: CGFloat) {
        let pose = studio.currentFrame?.pose ?? StickmanPose()
        let parentWorld = parentWorldAngle(of: bone, pose: pose)
        // Angle 0 points down: world angle = drag angle − π/2 − parent.
        let relative = normalizedAngle(worldDragAngle - .pi / 2 - parentWorld)
        studio.updateCurrentPose { $0.angles[bone] = relative }
    }

    private func parentWorldAngle(of bone: Bone, pose: StickmanPose) -> CGFloat {
        switch bone {
        case .torso:
            return pose.bodyRotation
        case .head:
            return pose.bodyRotation + (pose.angles[.torso] ?? .pi)
        case .leftUpperArm, .rightUpperArm, .leftThigh, .rightThigh:
            return pose.bodyRotation
        case .leftForearm:
            return pose.bodyRotation + (pose.angles[.leftUpperArm] ?? 0)
        case .rightForearm:
            return pose.bodyRotation + (pose.angles[.rightUpperArm] ?? 0)
        case .leftShin:
            return pose.bodyRotation + (pose.angles[.leftThigh] ?? 0)
        case .rightShin:
            return pose.bodyRotation + (pose.angles[.rightThigh] ?? 0)
        }
    }

    private func normalizedAngle(_ a: CGFloat) -> CGFloat {
        var a = a.truncatingRemainder(dividingBy: 2 * .pi)
        if a > .pi { a -= 2 * .pi }
        if a < -.pi { a += 2 * .pi }
        return a
    }
}

// MARK: - Rounded top corners shape

struct RoundedTopCorners: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Pose controls (bone list, fine angle slider, color)

private struct PoseControls: View {
    @Binding var selectedBone: Bone?
    let pose: StickmanPose
    let onRotate: (Bone, CGFloat) -> Void
    let onThickness: (CGFloat) -> Void
    let onScale: (CGFloat) -> Void
    let onBodyRotation: (CGFloat) -> Void
    let onColor: (UInt32) -> Void

    @State private var colorPickerShown = false

    private var angleBinding: Binding<Double> {
        Binding(
            get: {
                let bone = selectedBone ?? .torso
                return Double(pose.angles[bone] ?? 0)
            },
            set: {
                let bone = selectedBone ?? .torso
                onRotate(bone, CGFloat($0))
            }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            // Bone picker.
            Menu {
                ForEach(Bone.rotatable, id: \.self) { bone in
                    Button(bone.label) { selectedBone = bone }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selectedBone?.label ?? "Select bone")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
            }
            .frame(maxWidth: 150)

            // Fine angle slider for the selected bone.
            Slider(value: angleBinding, in: -3.15...3.15)
                .tint(Color(hex: 0xF5C451))
                .controlSize(.small)

            // Color.
            Button {
                colorPickerShown = true
            } label: {
                Circle()
                    .fill(pose.color)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                    .padding(3)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $colorPickerShown) {
                ColorPicker("Stickman color", selection: Binding(
                    get: { Color(hex: pose.colorARGB) },
                    set: { onColor(rgbaToARGB($0)) }
                ))
                .padding()
            }
        }
    }

    private func rgbaToARGB(_ color: Color) -> UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let R = UInt32(max(0, min(255, r * 255)))
        let G = UInt32(max(0, min(255, g * 255)))
        let B = UInt32(max(0, min(255, b * 255)))
        let A = UInt32(max(0, min(255, a * 255)))
        return (A << 24) | (R << 16) | (G << 8) | B
    }
}

// MARK: - Shared UI bits

struct StudioIconButton: View {
    let systemImage: String
    var prominent = false
    var tinted: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: prominent ? 15 : 12, weight: .semibold))
                .foregroundStyle(prominent ? AnyShapeStyle(.black) : AnyShapeStyle(tinted ?? Color.white.opacity(0.85)))
                .frame(width: prominent ? 40 : 30, height: prominent ? 40 : 28)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(prominent ? Color(hex: 0xF5C451) : Color.white.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Project browser sheet

struct ProjectBrowserSheet: View {
    @ObservedObject var studio: StudioState
    @Environment(\.dismiss) private var dismiss
    @State private var projects: [(url: URL, name: String, modified: Date)] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects, id: \.url) { item in
                    Button {
                        try? studio.load(from: item.url)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).fontWeight(.semibold)
                                Text(item.modified, style: .date)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if item.name == studio.project.name {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        AnimationProjectStore.delete(at: projects[index].url)
                    }
                    refresh()
                }
            }
            .navigationTitle("Animations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { refresh() }
        }
    }

    private func refresh() {
        projects = AnimationProjectStore.listProjects()
    }
}
