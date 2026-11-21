import SwiftUI

// MARK: - Animation Studio (main screen)

/// ANIMATE shows the timeline + playback + buttons + frames; DRAW strips
/// the studio chrome (hides the panel, timeline, controls) for a pure
/// canvas view.
enum StudioMode: Equatable {
    case animate, draw
}

struct AnimationStudioView: View {
    @ObservedObject var studio: StudioState
    @State private var selectedBone: Bone?
    @State private var projectsBrowserShown = false
    @State private var nameEditorShown = false
    /// First-time walkthrough, shown once per fighter.
    @State private var showTutorial = false
    /// ANIMATE shows the timeline + playback + buttons + frames; DRAW
    /// strips the studio chrome for a pure canvas view.
    @State private var mode: StudioMode = .animate

    var onBack: (() -> Void)?

    var body: some View {
        // Fixed rows: top bar, canvas (all remaining space), bottom bar.
        // No ZStack overlays / .position() — those let the panel size itself
        // freely and overlap the canvas and other controls.
        VStack(spacing: 0) {
            topBar
                .frame(height: topBarHeight)

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
                bottomInset: 0,
                ghostPoses: onionSkinGhosts,
                futureGhost: onionSkinFuture
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if mode == .animate {
                bottomPanel
            }
        }
        .background(Color(hex: 0x0C0D12).ignoresSafeArea())
        .onAppear {
            // A new blueprint's own lesson takes priority over the generic
            // walkthrough so first-time users see the move-specific pointers.
            if let game = studio.game, !game.hasSeenStudioTutorial, !studio.showBlueprintTutorial {
                showTutorial = true
            }
        }
        .sheet(isPresented: $showTutorial) {
            if let game = studio.game {
                StudioTutorialView(game: game)
            }
        }
        // Blueprint lesson — shown for an unlearned move. Only finishing it
        // unlocks the move for equipping in battle.
        .sheet(
            isPresented: Binding(
                get: { studio.showBlueprintTutorial },
                set: { studio.showBlueprintTutorial = $0 }
            )
        ) {
            if let blueprint = studio.editingBlueprint {
                BlueprintTutorialView(blueprint: blueprint) {
                    studio.game?.markBlueprintLearned(blueprint.id)
                    studio.showBlueprintTutorial = false
                    // Follow up with the general studio walkthrough if this is
                    // the fighter's first time in the studio.
                    if let game = studio.game, !game.hasSeenStudioTutorial {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showTutorial = true
                        }
                    }
                }
            }
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

    private var topBarHeight: CGFloat { 48 }
    private var bottomPanelHeight: CGFloat { 130 }

    /// Top bar: BACK, project chip, quality readout, mode tabs, save.
    private var topBar: some View {
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
    }

    /// Bottom panel — buttons in the left column, frames (the timeline) in
    /// the middle to right. No sliders.
    private var bottomPanel: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Left — the buttons.
            StudioButtonsRow(studio: studio, selectedBone: $selectedBone)
                .frame(width: 270)

            // Middle to right — the frames (timeline with gold playhead).
            FrameTimelineView(studio: studio)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(
            RoundedTopCorners(radius: 18)
                .fill(Color(hex: 0x14161E).opacity(0.97))
        )
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

// MARK: - Studio buttons (bottom-left, no sliders)

/// Bottom panel — the buttons live in the left column; the frames (the
/// timeline) sit in the middle to right. Rig editing happens in the canvas
/// top half via joint handles.
private struct StudioButtonsRow: View {
    @ObservedObject var studio: StudioState
    @Binding var selectedBone: Bone?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // One tidy row: playback, speed, ghosts, frame edits.
            HStack(alignment: .center, spacing: 6) {
                StudioIconButton(systemImage: "backward.end.fill") { studio.selectFrame(0) }
                BigPlayButton(studio: studio)
                PlaySpeedToggle(studio: studio)
                OnionToggleButton(studio: studio)
                FilmChipButton(studio: studio)
                StudioIconButton(
                    systemImage: studio.isMultiSelecting
                        ? "checkmark.circle.fill"
                        : "checkmark.circle"
                ) {
                    studio.setMultiSelecting(!studio.isMultiSelecting)
                }
                .accessibilityLabel("Select multiple frames")
                StudioIconButton(systemImage: "doc.on.doc") {
                    studio.duplicateFrame(at: studio.selectedIndex)
                }
                StudioIconButton(systemImage: "trash", tinted: Color(hex: 0xE86A6A)) {
                    if studio.isMultiSelecting, !studio.selectedFrameIDs.isEmpty {
                        studio.deleteSelectedFrames()
                    } else {
                        studio.deleteFrame(at: studio.selectedIndex)
                    }
                }
                Spacer(minLength: 0)
            }

            // Rig controls: which part, thickness, colour.
            PoseControlsRow(studio: studio, selectedBone: $selectedBone)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

/// The big play/stop button in the buttons row.
private struct BigPlayButton: View {
    @ObservedObject var studio: StudioState

    var body: some View {
        Button { studio.isPlaying ? studio.stop() : studio.play() } label: {
            Image(systemName: studio.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(studio.isPlaying ? .black : .white)
                .frame(width: 34, height: 34)
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
    }
}

/// Playback speed toggle.
private struct PlaySpeedToggle: View {
    @ObservedObject var studio: StudioState

    var label: String {
        switch studio.playbackSpeed {
        case 2: return "2×"
        case 0.5: return "½×"
        default: return "1×"
        }
    }

    var body: some View {
        Button { studio.cyclePlaybackSpeed() } label: {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(studio.playbackSpeed == 1 ? Color.white.opacity(0.85) : Color(hex: 0xF5C451))
                .frame(width: 34, height: 28)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

/// Onion-skin toggle — red ghosts of previous frames.
private struct OnionToggleButton: View {
    @ObservedObject var studio: StudioState

    var body: some View {
        Button { studio.onionSkin.toggle() } label: {
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
    }
}

/// Film-strip button on a gold chip — adds a frame.
private struct FilmChipButton: View {
    @ObservedObject var studio: StudioState

    var body: some View {
        Button { studio.addFrame() } label: {
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
    }
}

/// Pose controls — bone picker + thickness stepper + color. NO sliders.
private struct PoseControlsRow: View {
    @ObservedObject var studio: StudioState
    @Binding var selectedBone: Bone?
    @State private var colorPickerShown = false

    private var pose: StickmanPose { studio.currentFrame?.pose ?? StickmanPose() }
    private var bone: Bone { selectedBone ?? .torso }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Bone picker — which part you're editing.
            Menu {
                ForEach(Bone.rotatable, id: \.self) { b in
                    Button(b.label) { selectedBone = b }
                }
            } label: {
                Text(selectedBone?.label ?? "Torso")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF5C451))
            }
            .frame(width: 76, alignment: .leading)

            // Thickness stepper — minus, value, plus (no slider).
            HStack(alignment: .center, spacing: 3) {
                stepperButton("−") {
                    studio.updateCurrentPose { $0.thickness = max(0.4, $0.thickness - 0.4) }
                }
                Text("Thk \(String(format: "%.1f", pose.thickness))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 52, alignment: .center)
                stepperButton("+") {
                    studio.updateCurrentPose { $0.thickness = min(8, $0.thickness + 0.4) }
                }
            }

            // Color swatch + popover (no slider).
            Button { colorPickerShown = true } label: {
                Circle()
                    .fill(pose.color)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                    .padding(3)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $colorPickerShown) {
                ColorPicker("Stickman color", selection: Binding(
                    get: { pose.color },
                    set: { color in studio.updateCurrentPose { $0.colorARGB = rgbaToARGB(color) } }
                ))
                .padding()
            }
        }
    }

    private func stepperButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0xF5C451))
                .frame(width: 14, height: 28, alignment: .center)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

func rgbaToARGB(_ color: Color) -> UInt32 {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
    let R = UInt32(max(0, min(255, r * 255)))
    let G = UInt32(max(0, min(255, g * 255)))
    let B = UInt32(max(0, min(255, b * 255)))
    let A = UInt32(max(0, min(255, a * 255)))
    return (A << 24) | (R << 16) | (G << 8) | B
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
