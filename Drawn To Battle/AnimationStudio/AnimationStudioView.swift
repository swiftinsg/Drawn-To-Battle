import SwiftUI

// MARK: - Animation Studio (main screen)

struct AnimationStudioView: View {
    @ObservedObject var studio: StudioState
    @State private var selectedBone: Bone?
    @State private var projectsBrowserShown = false
    @State private var nameEditorShown = false
    /// First-time walkthrough, shown once per fighter.
    @State private var showTutorial = false
    /// Properties panel, used on compact screens where it cannot float over the canvas.
    @State private var showInspector = false

    var onBack: (() -> Void)?

    @State private var mode: StudioMode = .animate

    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.width < 700
            ZStack {
                // Paper canvas fits the area left of the inspector on wide
                // screens, and uses the full width on compact screens.
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
                    bottomInset: mode == .animate ? bottomPanelHeight : 0,
                    rightInset: mode == .animate && !compact ? inspectorWidth + 8 : 0,
                    topInset: topBarHeight,
                    ghostPoses: onionSkinGhosts
                )
                .ignoresSafeArea(edges: .bottom)

                // Studio chrome sits above the canvas: top bar first, then the
                // compact control dock pinned to the bottom. Keeping this in a
                // VStack stops the dock from centering over the fighter.
                VStack(spacing: 0) {
                    topBar(isCompact: compact)
                    Spacer(minLength: 0)
                    if mode == .animate {
                        bottomPanel
                    }
                }

                // Right-hand inspector floats over the canvas on wide screens.
                // On compact screens it opens as a sheet from the top bar.
                if mode == .animate && !compact {
                    StudioInspectorPanel(studio: studio, selectedBone: $selectedBone)
                        .frame(width: inspectorWidth, height: zoneHeight(geo))
                        .position(
                            x: geo.size.width - inspectorWidth / 2,
                            y: zoneTop(geo) + zoneHeight(geo) / 2
                        )
                }
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
        .sheet(isPresented: $showInspector) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("DONE") { showInspector = false }
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451))
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    StudioInspectorPanel(studio: studio, selectedBone: $selectedBone)
                        .frame(width: inspectorWidth)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
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

    // MARK: Regions

    /// Top bar: BACK, project chip, quality readout, mode tabs, tools.
    private func topBar(isCompact: Bool) -> some View {
        HStack(spacing: 8) {
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

            ModeTabs(mode: $mode)

            Spacer()

            Text(studio.hasUnsavedChanges ? "SAVING" : "AUTO SAVED")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
            if isCompact {
                StudioIconButton(systemImage: "slider.horizontal.3") { showInspector = true }
                    .accessibilityLabel("Properties")
            }
            StudioIconButton(systemImage: "questionmark.circle") { showTutorial = true }
                .accessibilityLabel("Tutorial")
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    /// Bottom zone: timeline, playback, and frame tools.
    private var bottomPanel: some View {
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
                        .frame(width: 52, height: 52)
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

            // Pose properties live in the right inspector, so the dock stays
            // compact and the whole figure remains visible above it.

            // Frame strip: add/duplicate/move/delete + clipboard.
            FrameMgmtStrip(studio: studio)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(height: bottomPanelHeight)
        .background(
            RoundedTopCorners(radius: 18)
                .fill(Color(hex: 0x14161E).opacity(0.97))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: Geometry helpers

    private var inspectorWidth: CGFloat { 240 }
    private var topBarHeight: CGFloat { 54 }
    /// Compact dock height after moving pose properties to the inspector.
    private var bottomPanelHeight: CGFloat { 176 }

    /// Space above the canvas zone (the top bar).
    private func zoneTop(_ geo: GeometryProxy) -> CGFloat { topBarHeight }

    /// Height of the canvas zone (between the top bar and bottom dock).
    private func zoneHeight(_ geo: GeometryProxy) -> CGFloat {
        max(0, geo.size.height - zoneTop(geo) - (mode == .animate ? bottomPanelHeight : 0))
    }

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

// MARK: - Studio mode

enum StudioMode: Equatable {
    case animate, draw
}

// MARK: - Mode tabs (reference: Animate / Draw)

private struct ModeTabs: View {
    @Binding var mode: StudioMode

    var body: some View {
        HStack(spacing: 6) {
            ModeTab(title: "ANIMATE", active: mode == .animate) { mode = .animate }
            ModeTab(title: "DRAW", active: mode == .draw) { mode = .draw }
        }
    }
}

private struct ModeTab: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(active ? AnyShapeStyle(Color(hex: 0xF5C451)) : AnyShapeStyle(Color.white.opacity(0.55)))
                .padding(EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(active ? Color(hex: 0xF5C451).opacity(0.14) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) mode")
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

}

// MARK: - Shared UI bits

func rgbaToARGB(_ color: Color) -> UInt32 {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
    let R = UInt32(max(0, min(255, r * 255)))
    let G = UInt32(max(0, min(255, g * 255)))
    let B = UInt32(max(0, min(255, b * 255)))
    let A = UInt32(max(0, min(255, a * 255)))
    return (A << 24) | (R << 16) | (G << 8) | B
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

            // Clipboard: copy the selected frame, paste it after the selection.
            Text("COPY")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xF5C451))
                .frame(width: 44, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: 0xF5C451).opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(hex: 0xF5C451).opacity(0.4), lineWidth: 1)
                )
                .onTapGesture { studio.copySelectedFrame() }
                .accessibilityLabel("Copy frame")
            Text("PASTE")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0xF5C451))
                .frame(width: 44, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: 0xF5C451).opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color(hex: 0xF5C451).opacity(0.4), lineWidth: 1)
                )
                .onTapGesture { studio.pasteFrame() }
                .accessibilityLabel("Paste frame")

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

// MARK: - Right inspector panel (reference: Properties)

/// Floating panel on the right of the canvas in ANIMATE mode:
/// the selected bone's transform and appearance.
private struct StudioInspectorPanel: View {
    @ObservedObject var studio: StudioState
    @Binding var selectedBone: Bone?
    @State private var colorPickerShown = false

    private var pose: StickmanPose { studio.currentFrame?.pose ?? StickmanPose() }
    private var bone: Bone { selectedBone ?? .torso }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROPERTIES")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 12)

            InspectorSection(title: "TRANSFORM") {
                InspectorRow(label: "X", binding: rootXBinding, range: 0...420,
                             display: "\(Int(pose.root.x.rounded()))")
                InspectorRow(label: "Y", binding: rootYBinding, range: 0...520,
                             display: "\(Int(pose.root.y.rounded()))")
                InspectorRow(label: "ANGLE", binding: boneAngleDegreesBinding, range: 0...360,
                             display: String(format: "%.0f°", boneDegrees))
                InspectorRow(label: "BODY", binding: bodyAngleDegreesBinding, range: 0...360,
                             display: String(format: "%.0f°", bodyDegrees))
                InspectorRow(label: "WIDTH", binding: thicknessBinding, range: 2...14,
                             display: "\(Int(pose.thickness.rounded()))")
                InspectorRow(label: "SCALE", binding: scaleBinding, range: 0.5...2.0,
                             display: String(format: "%.1f", pose.scale))
            }
            .padding(.horizontal, 12)

            InspectorSection(title: "APPEARANCE") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(pose.color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white.opacity(0.45), lineWidth: 1))
                        .onTapGesture { colorPickerShown = true }
                    Text(hexText)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .onTapGesture { colorPickerShown = true }
            }
            .padding(.horizontal, 12)

            Spacer()
        }
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: 0x121420))
                .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
        )
        .popover(isPresented: $colorPickerShown) {
            ColorPicker("Stickman color", selection: Binding(
                get: { pose.color },
                set: { color in studio.updateCurrentPose { $0.colorARGB = rgbaToARGB(color) } }
            ))
            .padding()
        }
    }

    // MARK: Bindings

    private var rootXBinding: Binding<Double> {
        Binding(
            get: { Double(pose.root.x) },
            set: { x in studio.updateCurrentPose { $0.root.x = CGFloat(x).clamped(10...390) } }
        )
    }

    private var rootYBinding: Binding<Double> {
        Binding(
            get: { Double(pose.root.y) },
            set: { y in studio.updateCurrentPose { $0.root.y = CGFloat(y).clamped(30...505) } }
        )
    }

    private var boneDegrees: Double { normalizedDegrees(Double(degrees(pose.angles[bone] ?? 0))) }

    private var bodyDegrees: Double { normalizedDegrees(Double(degrees(pose.bodyRotation))) }

    private var boneAngleDegreesBinding: Binding<Double> {
        Binding(
            get: { boneDegrees },
            set: { value in studio.updateCurrentPose { $0.angles[bone] = radians(value) } }
        )
    }

    private var bodyAngleDegreesBinding: Binding<Double> {
        Binding(
            get: { bodyDegrees },
            set: { value in studio.updateCurrentPose { $0.bodyRotation = radians(value) } }
        )
    }

    private var thicknessBinding: Binding<Double> {
        Binding(
            get: { Double(pose.thickness) },
            set: { value in studio.updateCurrentPose { $0.thickness = CGFloat(value).clamped(2...14) } }
        )
    }

    private var scaleBinding: Binding<Double> {
        Binding(
            get: { Double(pose.scale) },
            set: { scale in studio.updateCurrentPose { $0.scale = CGFloat(scale).clamped(0.5...2.0) } }
        )
    }

    private func degrees(_ radians: CGFloat) -> CGFloat {
        radians * 180 / .pi
    }

    private func radians(_ degrees: Double) -> CGFloat {
        CGFloat(degrees) * .pi / 180
    }

    private func normalizedDegrees(_ value: Double) -> Double {
        let wrapped = value.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }

    private var hexText: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(pose.color).getRed(&r, green: &g, blue: &b, alpha: &a)
        func hex(_ v: CGFloat) -> String {
            String(format: "%02X", Int(max(0, min(1, v)) * 255))
        }
        return "#\(hex(r))\(hex(g))\(hex(b))"
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.7))
                .tracking(0.8)
            content()
        }
    }
}

private struct InspectorRow: View {
    let label: String
    let binding: Binding<Double>
    let range: ClosedRange<Double>
    let display: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 36, alignment: .leading)
            Slider(value: binding, in: range)
                .tint(Color(hex: 0xF5C451))
                .controlSize(.small)
            Text(display)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 44, alignment: .trailing)
        }
    }
}

extension CGFloat {
    fileprivate func clamped(_ range: ClosedRange<CGFloat>) -> CGFloat {
        var result = self
        if result < range.lowerBound { result = range.lowerBound }
        if result > range.upperBound { result = range.upperBound }
        return result
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
