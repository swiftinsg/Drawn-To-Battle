import SwiftUI

// MARK: - Battle screen

struct BattleView: View {
    let boss: BossDefinition
    @ObservedObject var game: GameSave
    var onExit: () -> Void

    @StateObject private var engine: BattleEngine
    @State private var showTips = false
    @State private var showPause = false

    init(boss: BossDefinition, game: GameSave, onExit: @escaping () -> Void) {
        self.boss = boss
        self.game = game
        self.onExit = onExit

        let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .screen.bounds.size
            ?? CGSize(width: 852, height: 393)
        let project = game.equipped?.project ?? PoseTemplate.animation(for: .punch, name: "Default Jab")
        let analysis = AnimationAnalysis.analyze(project)
        var mult = 1.0
        if case .blueprint(let id) = game.equipped?.source,
           let bp = BlueprintCatalog.blueprint(id: id) {
            mult = bp.rarity.damageMultiplier
        }
        _engine = StateObject(wrappedValue: BattleEngine(
            boss: boss,
            project: project,
            analysis: analysis,
            blueprintMult: mult,
            arena: CGSize(width: max(screen.width, screen.height), height: min(screen.width, screen.height))
        ))
    }

    var body: some View {
        ZStack {
            Color(hex: 0x07080C).ignoresSafeArea()

            TimelineView(.animation) { _ in
                Canvas { context, size in
                    drawScene(&context, size: size)
                }
            }
            .ignoresSafeArea()

            // HUD.
            VStack(spacing: 6) {
                BattleHUD(engine: engine, boss: boss)
                Spacer()
            }
            .allowsHitTesting(false)

            // Controls.
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    JoystickZone(engine: engine)
                        .frame(width: 130, height: 130)
                    Spacer()
                    ControlCluster(engine: engine)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 10)
            }

            if showTips {
                BattleTipsOverlay(technique: boss.requiredTechnique, onClose: {
                    showTips = false
                    UserDefaults.standard.set(true, forKey: "dtb.seenTips.v2")
                })
            }

            if let result = engine.result {
                BattleResultOverlay(
                    result: result,
                    boss: boss,
                    engine: engine,
                    game: game,
                    onExit: onExit,
                    onRetry: { engine.reset() }
                )
            }

            if showPause {
                BattlePauseOverlay(
                    onContinue: resumeBattle,
                    onExit: exitBattle
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            // Fresh start every time the battle is entered — hard-reset so
            // the end screen is a new screen, never a stale result from a
            // previous run.
            engine.reset()
            engine.startLoop()
            if !UserDefaults.standard.bool(forKey: "dtb.seenTips.v2") {
                showTips = true
            }
        }
        .onDisappear { engine.stopLoop() }
        .statusBarHidden(true)
        .overlay(alignment: .topTrailing) {
            if engine.result == nil && !showTips && !showPause {
                Button { pauseBattle() } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 14)
                .padding(.top, 62)
                .accessibilityLabel("Pause battle")
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showPause)
    }

    // MARK: Pause controls

    private func pauseBattle() {
        engine.stopLoop()
        engine.input = BattleInput()
        withAnimation(.easeInOut(duration: 0.18)) { showPause = true }
    }

    private func resumeBattle() {
        withAnimation(.easeInOut(duration: 0.18)) { showPause = false }
        engine.startLoop()
    }

    private func exitBattle() {
        engine.stopLoop()
        onExit()
    }

    // MARK: Scene drawing

    private func drawScene(_ context: inout GraphicsContext, size: CGSize) {
        let groundY = engine.groundY

        drawBackground(&context, size: size, groundY: groundY)

        // Screen shake.
        let sx = sin(engine.time * 67) * engine.shake
        let sy = cos(engine.time * 81) * engine.shake * 0.6
        context.translateBy(x: sx, y: sy)

        // Boss character.
        BossRenderer.draw(&context, engine: engine)

        // Telegraph ring + attack hint (around the boss).
        drawTelegraph(&context)

        // Player afterimages, then the player.
        for ghost in engine.afterimages {
            let pose = ghost.pose
            let alpha = 0.28 * (ghost.life / ghost.maxLife)
            StickmanRenderer.draw(
                &context, pose: pose, hipAt: ghost.hip, mirror: ghost.mirror,
                tint: Color(hex: 0xF5C451).opacity(alpha)
            )
        }
        drawPlayer(&context)

        // Projectiles with trails.
        for p in engine.projectiles {
            for trail in 1...3 {
                let t = CGFloat(trail) * 0.045
                let tp = CGPoint(x: p.pos.x - p.vel.dx * t, y: p.pos.y - p.vel.dy * t)
                context.fill(
                    Path(ellipseIn: CGRect(x: tp.x - p.radius * 0.8, y: tp.y - p.radius * 0.8,
                                           width: p.radius * 1.6, height: p.radius * 1.6)),
                    with: .color(p.color.opacity(0.14))
                )
            }
            let rect = CGRect(x: p.pos.x - p.radius, y: p.pos.y - p.radius, width: p.radius * 2, height: p.radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(p.color))
            context.fill(
                Path(ellipseIn: rect.insetBy(dx: -5, dy: -5)),
                with: .color(p.color.opacity(0.25))
            )
        }

        // Particles.
        for particle in engine.particles {
            let alpha = Double(particle.life / particle.maxLife)
            let r = particle.size
            context.fill(
                Path(ellipseIn: CGRect(x: particle.pos.x - r, y: particle.pos.y - r, width: r * 2, height: r * 2)),
                with: .color(particle.color.opacity(alpha))
            )
        }

        // Floaters (damage numbers, hints).
        for f in engine.floaters {
            let alpha = Double(min(1, f.life / 0.35))
            context.draw(
                Text(f.text)
                    .font(.system(size: f.big ? 22 : 14, weight: .heavy, design: .rounded))
                    .foregroundColor(f.color.opacity(alpha)),
                at: f.pos
            )
        }

        // Solar flare flash.
        if engine.flareTimer > 0 {
            context.fill(
                Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                with: .color(Color(hex: boss.accentColor).opacity(0.35 * min(1, engine.flareTimer * 3)))
            )
        }

        drawLowHPWarning(&context, size: size)
    }

    private func drawBackground(_ context: inout GraphicsContext, size: CGSize, groundY: CGFloat) {
        // Parallax stars: two layers drifting at different speeds.
        var seeded = SeededRandom(seed: 7)
        for i in 0..<80 {
            let baseX = CGFloat(seeded.next()) * size.width
            let baseY = CGFloat(seeded.next()) * groundY * 0.92
            let r = CGFloat(seeded.next()) * 1.6 + 0.6
            let drift = CGFloat(i % 2 == 0 ? 1 : 2) * sin(engine.time * (i % 2 == 0 ? 0.35 : 0.6)) * 14
            let twinkle = 0.25 + Double(seeded.next()) * 0.4 + 0.15 * sin(engine.time * 2 + Double(i))
            context.fill(
                Path(ellipseIn: CGRect(x: baseX + drift, y: baseY, width: r, height: r)),
                with: .color(.white.opacity(max(0.08, twinkle)))
            )
        }

        // Distant planet ring (decorative arc).
        let ringCenter = CGPoint(x: size.width - 190, y: groundY - 330)
        var ring = Path()
        ring.addArc(center: ringCenter, radius: 120,
                    startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        context.stroke(ring, with: .color(Color(hex: boss.bodyColor).opacity(0.3)), lineWidth: 5)

        // Boss-side glow.
        let glow = CGRect(x: size.width - 380, y: groundY - 420, width: 380, height: 380)
        context.fill(
            Path(ellipseIn: glow),
            with: .radialGradient(
                Gradient(colors: [Color(hex: boss.bodyColor).opacity(0.3), .clear]),
                center: CGPoint(x: glow.midX, y: glow.midY),
                startRadius: 10, endRadius: 260
            )
        )

        // Floor with perspective streaks.
        context.fill(
            Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
            with: .color(Color(hex: 0x12141C))
        )
        var floorLine = Path()
        floorLine.move(to: CGPoint(x: 0, y: groundY))
        floorLine.addLine(to: CGPoint(x: size.width, y: groundY))
        context.stroke(floorLine, with: .color(.white.opacity(0.25)), lineWidth: 2)
        for i in 0..<7 {
            let x = size.width * CGFloat(i) / 6
            var streak = Path()
            streak.move(to: CGPoint(x: x, y: groundY + 4))
            streak.addLine(to: CGPoint(x: x + (x - size.width / 2) * 0.35, y: size.height))
            context.stroke(streak, with: .color(.white.opacity(0.05)), lineWidth: 1.5)
        }
    }

    private func drawTelegraph(_ context: inout GraphicsContext) {
        let a = BossRenderer.anchor(for: engine)
        let center = CGPoint(x: a.origin.x, y: a.origin.y - a.bodyRadius * 0.55)

        if engine.bossState == .telegraph {
            let pulse = 1 + 0.08 * sin(engine.time * 18)
            context.stroke(
                Path(ellipseIn: CGRect(x: center.x - a.bodyRadius * pulse * 1.35,
                                       y: center.y - a.bodyRadius * pulse * 1.35,
                                       width: a.bodyRadius * 2.7 * pulse, height: a.bodyRadius * 2.7 * pulse)),
                with: .color(.white.opacity(0.75)),
                lineWidth: 3
            )
            context.draw(
                Text("\(engine.currentAttackName) — \(engine.currentAttack?.kind.hint ?? "GET READY")")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white),
                at: CGPoint(x: center.x, y: max(center.y - a.bodyRadius - 40, 150))
            )
        }

        if engine.bossState == .attack, let atk = engine.currentAttack {
            context.draw(
                Text(atk.name)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: boss.accentColor)),
                at: CGPoint(x: center.x, y: max(center.y - a.bodyRadius - 36, 150))
            )
        }
    }

    private func drawPlayer(_ context: inout GraphicsContext) {
        // Shadow.
        let airHeight = max(0, (engine.groundY - 45) - engine.playerPos.y)
        let shadowScale = max(0.5, 1 - airHeight / 260)
        context.fill(
            Path(ellipseIn: CGRect(x: engine.playerPos.x - 22 * shadowScale, y: engine.groundY - 6,
                                   width: 44 * shadowScale, height: 9)),
            with: .color(.black.opacity(0.35 * shadowScale))
        )

        var pose = engine.currentPoseForRender()
        pose.scale = 0.62
        pose.thickness = 7

        var tint: Color? = nil
        if engine.flashPlayer > 0 { tint = .white }
        if engine.invulnTimer > 0 && engine.hurtTimer <= 0 && !engine.dodgeActive {
            tint = Color.white.opacity(0.55)
        }

        let mirror = engine.facing == -1
        StickmanRenderer.draw(&context, pose: pose, hipAt: engine.playerPos, mirror: mirror, tint: tint)

        // Block shield arc.
        if engine.blockActive {
            let dir: CGFloat = engine.facing == 1 ? 1 : -1
            let cx = engine.playerPos.x + dir * 12
            let cy = engine.playerPos.y - 42
            var arc = Path()
            arc.addArc(center: CGPoint(x: cx, y: cy), radius: 40,
                       startAngle: .degrees(dir > 0 ? -62 : 118),
                       endAngle: .degrees(dir > 0 ? 62 : 242), clockwise: false)
            // Parry window glows gold; normal block glows blue.
            let parrying = (engine.time - engine.blockStart) <= 0.22
            context.stroke(
                arc,
                with: .color(parrying ? Color(hex: 0xF5C451) : Color(hex: 0x4C8DFF)),
                style: StrokeStyle(lineWidth: parrying ? 5 : 4, lineCap: .round)
            )
        }

        // Ultimate charge glow.
        if engine.attackActive && engine.currentIsUltimate {
            context.stroke(
                Path(ellipseIn: CGRect(x: engine.playerPos.x - 55, y: engine.playerPos.y - 55, width: 110, height: 110)),
                with: .color(Color(hex: 0xF5C451).opacity(0.6)),
                lineWidth: 3
            )
        }
    }

    private func drawLowHPWarning(_ context: inout GraphicsContext, size: CGSize) {
        guard engine.playerHP < 30, engine.result == nil else { return }
        let pulse = 0.5 + 0.5 * sin(engine.time * 6)
        let gradient = Gradient(colors: [.clear, .clear, Color(hex: 0xE86A6A).opacity(0.28 * pulse)])
        context.fill(
            Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)),
            with: .radialGradient(
                gradient,
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                startRadius: size.width * 0.28,
                endRadius: size.width * 0.72
            )
        )
    }
}

// MARK: - HUD

private struct BattleHUD: View {
    @ObservedObject var engine: BattleEngine
    let boss: BossDefinition

    var body: some View {
        HStack(spacing: 14) {
            // Player side.
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if engine.comboCount >= 2 {
                        Text("×\(engine.comboCount) COMBO")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(hex: 0xF5C451).opacity(0.15)))
                    }
                    HPBar(percent: engine.playerHP / 100, color: Color(hex: 0xF5C451))
                }
                UltMeter(percent: engine.ultMeter / 100)
            }
            .frame(maxWidth: 300)

            // Technique requirement chip.
            VStack(spacing: 2) {
                Text("DEFEAT WITH")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Text(boss.requiredTechnique.label)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF5C451))
                // Your animation's quality drives damage — show the score.
                Text("POWER \(Int(engine.analysis.power)) • \(engine.analysis.powerLabel)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.07)))

            Spacer()

            // Boss side.
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(boss.bossName)\(engine.phaseTwo ? "  •  PHASE 2" : "")")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                HPBar(percent: engine.bossHP / engine.bossHPMax, color: Color(hex: 0xE86A6A))
                StaggerBar(percent: engine.bossStunTimer > 0 ? 1 : engine.bossStagger / engine.bossStaggerMax,
                           stunned: engine.bossStunTimer > 0)
            }
            .frame(maxWidth: 300)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

private struct HPBar: View {
    let percent: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * percent))
            }
        }
        .frame(height: 12)
        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
        .animation(.linear(duration: 0.15), value: percent)
    }
}

private struct UltMeter: View {
    let percent: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(Color(hex: 0xA86CFF))
                    .frame(width: max(0, geo.size.width * percent))
            }
        }
        .frame(height: 6)
        .overlay(
            Text(percent >= 1 ? "ULTIMATE READY — TAP ULT" : "ULTIMATE")
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
        )
        .animation(.linear(duration: 0.15), value: percent)
    }
}

private struct StaggerBar: View {
    let percent: Double
    let stunned: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(Color(hex: 0xA86CFF).opacity(stunned ? 1 : 0.75))
                    .frame(width: max(0, geo.size.width * percent))
            }
        }
        .frame(height: 5)
        .overlay(
            Text(stunned ? "STUNNED — ATTACK!" : "STAGGER")
                .font(.system(size: 6.5, weight: .black, design: .rounded))
                .foregroundStyle(stunned ? Color(hex: 0xA86CFF) : .white.opacity(0.5))
        )
        .animation(.linear(duration: 0.12), value: percent)
    }
}

// MARK: - Controls

private struct JoystickZone: View {
    @ObservedObject var engine: BattleEngine
    @State private var knob: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 2))
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 52, height: 52)
                    .offset(knob)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dx = value.location.x - center.x
                        let dy = value.location.y - center.y
                        let len = max(1, sqrt(dx * dx + dy * dy))
                        let maxR: CGFloat = 42
                        let clamped = min(len, maxR)
                        knob = CGSize(width: dx / len * clamped, height: dy / len * clamped)
                        engine.input.move = CGVector(
                            dx: Double(dx / len * clamped / maxR),
                            dy: Double(dy / len * clamped / maxR)
                        )
                    }
                    .onEnded { _ in
                        knob = .zero
                        engine.input.move = .zero
                    }
            )
        }
    }
}

private struct ControlCluster: View {
    @ObservedObject var engine: BattleEngine

    var body: some View {
        // 2×2 cluster: BLOCK / ULT on top, DODGE / ATTACK on the bottom.
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                BlockButton(engine: engine)
                UltButton(engine: engine)
            }
            HStack(spacing: 10) {
                DodgeButton(engine: engine)
                AttackButton(engine: engine)
            }
        }
    }
}

private struct BlockButton: View {
    @ObservedObject var engine: BattleEngine
    @State private var pressed = false

    private var parryGlow: Bool {
        engine.blockActive && (engine.time - engine.blockStart) <= 0.22
    }

    var body: some View {
        Text("BLOCK")
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(pressed ? .black : Color(hex: 0x4C8DFF))
            .frame(width: 62, height: 62)
            .background(Circle().fill(pressed ? Color(hex: 0x4C8DFF) : Color.white.opacity(0.08)))
            .overlay(Circle().stroke((parryGlow ? Color(hex: 0xF5C451) : Color(hex: 0x4C8DFF)).opacity(pressed ? 1 : 0.6), lineWidth: parryGlow ? 4 : 2))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        pressed = true
                        engine.input.blockHeld = true
                    }
                    .onEnded { _ in
                        pressed = false
                        engine.input.blockHeld = false
                    }
            )
    }
}

private struct UltButton: View {
    @ObservedObject var engine: BattleEngine
    private var ready: Bool { engine.ultMeter >= 100 }

    var body: some View {
        Button {
            if ready { engine.input.ultimateQueued = true }
        } label: {
            ZStack {
                Circle()
                    .fill(ready ? Color(hex: 0xA86CFF) : Color.white.opacity(0.08))
                    .frame(width: 62, height: 62)
                if ready {
                    Circle()
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                        .frame(width: 70, height: 70)
                        .scaleEffect(1 + 0.04 * sin(engine.time * 6))
                }
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    .frame(width: 62, height: 62)
                Text("ULT")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(ready ? .black : .white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DodgeButton: View {
    @ObservedObject var engine: BattleEngine
    private var ready: Bool { engine.dodgeCooldown <= 0 }

    var body: some View {
        Button {
            engine.input.dodgeQueued = true
        } label: {
            Circle()
                .fill(ready ? Color(hex: 0x5FBF6E).opacity(0.85) : Color.white.opacity(0.08))
                .frame(width: 58, height: 58)
                .overlay(Circle().stroke(Color(hex: 0x5FBF6E).opacity(0.6), lineWidth: 2))
                .overlay(
                    Text("DODGE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(ready ? .black : .white.opacity(0.45))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct AttackButton: View {
    @ObservedObject var engine: BattleEngine

    var body: some View {
        Button {
            engine.input.attackQueued = true
        } label: {
            Circle()
                .fill(Color(hex: 0xF5C451))
                .frame(width: 80, height: 80)
                .overlay(
                    Text("ATTACK")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tips overlay (first battle)

private struct BattleTipsOverlay: View {
    let technique: CombatTechnique
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("HOW TO FIGHT")
                    .font(DrawnToBattleTypography.display(26))
                    .foregroundStyle(Color(hex: 0xF5C451))

                tip(icon: "sparkles", title: "MATCH THE TECHNIQUE",
                    text: "This boss only fears \(technique.label) strikes. Mismatched attacks barely scratch it.")
                tip(icon: "arrow.triangle.swap", title: "DODGE",
                    text: "Tap DODGE to roll with invincibility frames. Roll through projectiles and charges.")
                tip(icon: "hand.raised", title: "PARRY",
                    text: "Tap BLOCK just before an attack lands (the shield flashes gold) to negate it and build STAGGER.")
                tip(icon: "bolt", title: "STAGGER & ULTIMATE",
                    text: "Fill the purple STAGGER bar to stun the boss, then unload. Combos add up to +40% damage.")

                Button(action: onClose) {
                    Text("LET'S FIGHT")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color(hex: 0xF5C451)))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: 0x14161E))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1))
            )
            .padding(28)
        }
    }

    private func tip(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: 0xF5C451))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Pause overlay

private struct BattlePauseOverlay: View {
    let onContinue: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()

            VStack(spacing: 18) {
                Text("PAUSED")
                    .font(DrawnToBattleTypography.display(38))
                    .foregroundStyle(.white)

                Text("Your fight is on hold.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                VStack(spacing: 10) {
                    Button {
                        onContinue()
                    } label: {
                        Text("CONTINUE")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: 220)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color(hex: 0xF5C451)))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onExit()
                    } label: {
                        Text("EXIT")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: 220)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
        }
    }
}

// MARK: - Result overlay

private struct BattleResultOverlay: View {
    let result: BattleResult
    let boss: BossDefinition
    let engine: BattleEngine
    @ObservedObject var game: GameSave
    var onExit: () -> Void
    var onRetry: () -> Void

    private var stars: Int {
        if engine.damageTaken <= 0.5 { return 3 }
        if engine.damageTaken < 35 { return 2 }
        return 1
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.76).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(result == .victory ? "VICTORY!" : "DEFEATED")
                    .font(DrawnToBattleTypography.display(42))
                    .foregroundStyle(result == .victory ? Color(hex: 0xF5C451) : Color(hex: 0xE86A6A))

                if result == .victory {
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundStyle(i < stars ? Color(hex: 0xF5C451) : Color.white.opacity(0.2))
                        }
                    }
                    let firstClear = !game.defeatedBosses.contains(boss.id + "_rewarded")
                    Text("+\(boss.coinReward(firstClear: firstClear)) COINS • +\(boss.penReward(firstClear: firstClear)) PENS")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451))
                    Text("+\(boss.xpReward(firstClear: firstClear)) XP")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("YOUR ANIMATION — POWER \(Int(engine.analysis.power)) • \(engine.analysis.powerLabel)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("\(boss.bossName) only fears \(boss.requiredTechnique.label) moves.\nSharpen your animation and try again.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                }

                // Battle stats.
                HStack(spacing: 0) {
                    stat("TIME", String(format: "%.1fs", engine.battleTime))
                    stat("MAX COMBO", "×\(engine.maxCombo)")
                    stat("PARRIES", "\(engine.parries)")
                    stat("DMG TAKEN", "\(Int(engine.damageTaken))")
                }
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                HStack(spacing: 14) {
                    Button {
                        if result == .victory { game.registerVictory(boss: boss) }
                        onRetry()
                    } label: {
                        Text(result == .victory ? "FIGHT AGAIN" : "RETRY")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color(hex: 0xF5C451)))
                    }
                    .buttonStyle(.plain)

                    Button {
                        if result == .victory { game.registerVictory(boss: boss) }
                        onExit()
                    } label: {
                        Text("EXIT")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Seeded random (stable star field)

struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
    }
}
