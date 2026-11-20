import SwiftUI

// MARK: - Animation Studio (main screen)

struct AnimationStudioView: View {
    @ObservedObject var studio: StudioState
    @State private var selectedBone: Bone?
    @State private var projectsBrowserShown = false
    @State private var nameEditorShown = false
    /// First-time walkthrough, shown once per fighter.
    @State private var showTutorial = false

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
                topInset: topBarHeight,
                ghostPoses: onionSkinGhosts,
                futureGhost: onionSkinFuture
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

                    // Live quality readout, re-scored on every edit, and the
                    // same score that sets battle damage.
                    let live = AnimationAnalysis.analyze(studio.project)
                    Text("POWER \(Int(live.power)) • \(live.powerLabel)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: 0xF5C451).opacity(0.1)))
                        .lineLimit(1)

                    Spacer()

                    Text(studio.hasUnsavedChanges ? "SAVING" : "AUTO SAVED")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                    StudioIconButton(systemImage: "questionmark.circle") { showTutorial = true }
                        .accessibilityLabel("Tutorial")
                    StudioIconButton(systemImage: "folder") { projectsBrowserShown = true }
                    StudioIconButton(systemImage: "plus.rectangle.on.rectangle") { studio.newProject() }
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 4)

                Spacer()

                // Studio controls, arranged from the top of the bottom zone
                // down: timeline, playback, pose strip, frame strip.
                VStack(spacing: 8) {
                    // Timeline with gold playhead.
                    FrameTimelineView(studio: studio)

                    // Playback row, the starring zone: big STOP/PLAY and
                    // back/forward buttons, speed toggle.
                    HStack(spacing: 10) {
                        StudioIconButton(systemImage: "backward.end.fill") { studio.selectFrame(0) }

                        Button {
                            studio.isPlaying ? studio.stop() : studio.play()
                        } label: {
                            Image(systemName: studio.isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(studio.isPlaying ? .black : .white)
                                .frame(width: 64, height: 64)
                                .background(
                                    Circle().fill(studio.isPlaying
                                        ? Color.white.opacity(0.12)
                                        : Color(hex: 0xF5C451)))
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                                .shadow(color: Color(hex: 0xF5C451).opacity(0.3), radius: 8, y: 2)
                        }
                        .buttonStyle(SquashButtonStyle())

                        // Playback speed toggle.
                        Button {
                            studio.cyclePlaybackSpeed()
                        } label: {
                            Text(speedLabel)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(studio.playbackSpeed == 1 ? Color.white.opacity(0.85) : Color(hex: 0xF5C451))
                                .frame(width: 40, height: 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    // Pose strip: bone picker, angle, thickness, scale, color.
                    PoseStrip(
                        selectedBone: $selectedBone,
                        pose: studio.currentFrame?.pose ?? StickmanPose(),
                        onRotate: handleRotate,
                        onSetAngle: setBoneAngle,
                        onThickness: { value in
                            studio.updateCurrentPose { pose in pose.thickness = value }
                        },
                        onScale: { value in
                            studio.updateCurrentPose { pose in pose.scale = value }
                        },
                        onBodyRotation: { radians in
                            studio.updateCurrentPose { pose in
                                pose.bodyRotation = self.normalizedAngle(radians)
                            }
                        },
                        onColor: { value in
                            studio.updateCurrentPose { pose in pose.colorARGB = value }
                        }
                    )

                    // Frame strip: add/duplicate/move/delete.
                    FrameMgmtStrip(studio: studio)
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
        .onAppear {
            if let game = studio.game, !game.hasSeenStudioTutorial {
                showTutorial = true
            }
        }
        .sheet(isPresented: $showTutorial) {
            if let game = studio.game {
                StudioTutorialView(game: game)
            }
        }
        // Blueprint tutorial, shown the first time a blueprint is opened.
        .sheet(
            isPresented: Binding(
                get: { studio.showBlueprintTutorial },
                set: { studio.showBlueprintTutorial = $0 }
            )
        ) {
            BlueprintTutorialView { studio.showBlueprintTutorial = false }
        }
        .onDisappear {
            studio.stop()
            studio.flushAutosave()
        }
        .sheet(isPresented: $projectsBrowserShown) {
            ProjectBrowserSheet(studio: studio)
        }
        .alert("Project name", isPresented: $nameEditorShown) {
            TextField("Name", text: Binding(
                get: { studio.project.name },
                set: { studio.project.name = $0; studio.markProjectChanged() }
            ))
            Button("OK") {}
        }
    }

    /// Height of the overlaid bottom panel, timeline + playback + pose
    /// strip + frame strip, used by the canvas to keep the figure and
    /// floor line above it.
    private var topBarHeight: CGFloat { 48 }
    private var bottomPanelHeight: CGFloat { 264 }

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

    /// The next frame ghost, drawn in blue when onion skin is on.
    private var onionSkinFuture: StickmanPose? {
        guard studio.onionSkin,
              studio.project.frames.indices.contains(studio.selectedIndex + 1) else { return nil }
        return studio.project.frames[studio.selectedIndex + 1].pose
    }

    // MARK: Rotation conversion

    /// Slider edits set the bone's stored angle directly, in radians.
    private func setBoneAngle(_ bone: Bone, radians: CGFloat) {
        studio.updateCurrentPose { $0.angles[bone] = self.normalizedAngle(radians) }
    }

    /// Convert a drag's world angle into the bone's stored relative angle.
    private func handleRotate(bone: Bone, worldDragAngle: CGFloat) {
        let pose = studio.currentFrame?.pose ?? StickmanPose()
        let parentWorld = parentWorldAngle(of: bone, pose: pose)
        // Angle 0 points down: world angle is drag angle minus π/2 minus parent.
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

// MARK: - Pose strip
//
// Controls for the selected pose: bone picker, angle slider with live
// value display, thickness, scale, body rotation, and color.

private struct PoseStrip: View {
    @Binding var selectedBone: Bone?
    let pose: StickmanPose
    let onRotate: (Bone, CGFloat) -> Void
    let onSetAngle: (Bone, CGFloat) -> Void
    let onThickness: (CGFloat) -> Void
    let onScale: (CGFloat) -> Void
    let onBodyRotation: (CGFloat) -> Void
    let onColor: (UInt32) -> Void

    @State private var colorPickerShown = false

    var angleDisplay: String {
        String(format: "%3.0f°", Self.degrees(from: pose.angles[selectedBone ?? .torso] ?? 0))
    }

    /// Angles are stored in radians but shown and edited as 0 through 360.
    private static func degrees(from radians: CGFloat) -> Double {
        let raw = radians * 180 / .pi
        let wrapped = raw.truncatingRemainder(dividingBy: 360)
        return Double(wrapped < 0 ? wrapped + 360 : wrapped)
    }

    var thicknessDisplay: String {
        String(format: "%0.1f", pose.thickness)
    }

    var scaleDisplay: String {
        String(format: "%0.1f", pose.scale)
    }

    private var angleBinding: Binding<Double> {
        Binding(
            get: {
                let bone = selectedBone ?? .torso
                return Self.degrees(from: pose.angles[bone] ?? 0)
            },
            set: {
                let bone = selectedBone ?? .torso
                onSetAngle(bone, CGFloat($0) * .pi / 180)
            }
        )
    }

    private var thicknessBinding: Binding<Double> {
        Binding(
            get: { Double(pose.thickness) },
            set: { onThickness(CGFloat($0)) }
        )
    }

    private var scaleBinding: Binding<Double> {
        Binding(
            get: { Double(pose.scale) },
            set: { onScale(CGFloat($0)) }
        )
    }

    private var rotationBinding: Binding<Double> {
        Binding(
            get: { Self.degrees(from: pose.bodyRotation) },
            set: { onBodyRotation(CGFloat($0) * .pi / 180) }
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            // Row 1: bone picker, angle, scale, color.
            HStack(spacing: 12) {
                // Bone picker, shows the selected bone's name.
                Menu {
                    ForEach(Bone.rotatable, id: \.self) { bone in
                        Button(bone.label) { selectedBone = bone }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedBone?.label ?? "Torso")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: 0xF5C451).opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: 0xF5C451).opacity(0.4), lineWidth: 1)
                            )
                    )
                }
                .frame(width: 118)

                // Angle slider (selected bone's relative angle).
                VStack(spacing: 2) {
                    Slider(value: angleBinding, in: 0...360)
                        .tint(Color(hex: 0xF5C451))
                        .controlSize(.small)
                    Text("Angle \(angleDisplay)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(width: 64)

                // Scale slider.
                VStack(spacing: 2) {
                    Slider(value: scaleBinding, in: 0.5...1.8)
                        .tint(Color(hex: 0xF5C451))
                        .controlSize(.small)
                    Text("Scale \(scaleDisplay)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(width: 64)

                // Body rotation slider.
                VStack(spacing: 2) {
                    Slider(value: rotationBinding, in: 0...360)
                        .tint(Color(hex: 0xF5C451))
                        .controlSize(.small)
                    Text("Rotate \(Int(Self.degrees(from: pose.bodyRotation)))°")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(width: 76)

                // Color button.
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

            // Row 2: thickness slider with live value.
            HStack(spacing: 12) {
                Text("Thickness")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 56, alignment: .leading)
                Slider(value: thicknessBinding, in: 0.4...8.0)
                    .tint(Color(hex: 0xF5C451))
                    .controlSize(.small)
                Text("\(thicknessDisplay)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xF5C451))
                    .frame(width: 34, alignment: .trailing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.white.opacity(0.04))
        )
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

// MARK: - Frame management strip
//
// Compact row of frame-management tools with clearly distinguished roles.

private struct FrameMgmtStrip: View {
    @ObservedObject var studio: StudioState

    var body: some View {
        HStack(spacing: 10) {
            // Frame management. The add-frame button carries the
            // hand-drawn film strip on a gold chip.
            Button {
                studio.addFrame()
            } label: {
                Image("DrawnToBattleFrameButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 11)
                    .frame(width: 30, height: 28)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color(hex: 0xF5C451)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    )
                    .stickerShadow()
                    .accessibilityLabel("Add frame")
            }
            .buttonStyle(SquashButtonStyle())

            // Second-pass copy of duplicates, increases contrast
            // between "safe" and "destructive" management.
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(studio.onionSkin ? Color(hex: 0xF5C451).opacity(0.6) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .accessibilityLabel(studio.onionSkin ? "Hide ghost frames" : "Show ghost frames")
            }
            .buttonStyle(.plain)

            Spacer()
        }
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
