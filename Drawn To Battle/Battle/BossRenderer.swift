import SwiftUI

// MARK: - Boss character renderer
//
// Draws each boss as a big stickman character (not a circle) with
// per-planet styling, telegraph/attack/stun poses and held props.

enum BossRenderer {

    struct Anchor {
        let origin: CGPoint      // hip position on screen
        let scale: CGFloat
        let thickness: CGFloat
        let mirror: Bool
        let bodyRadius: CGFloat
    }

    // MARK: Anchor

    static func anchor(for engine: BattleEngine) -> Anchor {
        let s = scale(for: engine.boss)
        return Anchor(
            origin: CGPoint(x: engine.bossX, y: engine.groundY - hipHeight(engine.boss) + bobOffset(engine)),
            scale: s,
            thickness: thickness(for: engine.boss),
            mirror: engine.bossX > engine.playerPos.x,
            bodyRadius: 30 * s
        )
    }

    private static func scale(for boss: BossDefinition) -> CGFloat {
        switch boss.id {
        case "earth": return 1.5
        case "mars": return 1.24
        default: return 1.3
        }
    }

    private static func thickness(for boss: BossDefinition) -> CGFloat {
        switch boss.id {
        case "earth": return 13
        case "mars": return 9
        default: return 10
        }
    }

    /// Standing hip height above the floor (legs slightly bent).
    private static func hipHeight(_ boss: BossDefinition) -> CGFloat {
        let s = scale(for: boss)
        switch boss.id {
        case "earth": return 64 * s
        case "mars": return 56 * s
        default: return 56 * s
        }
    }

    private static func bobOffset(_ engine: BattleEngine) -> CGFloat {
        if engine.bossStunTimer > 0 {
            return sin(engine.time * 14) * 3
        }
        return sin(engine.time * 2.2) * 4
    }

    // MARK: Draw

    static func draw(_ context: inout GraphicsContext, engine: BattleEngine) {
        let boss = engine.boss
        let a = anchor(for: engine)
        let accent = Color(hex: boss.accentColor)

        // Shadow.
        context.fill(
            Path(ellipseIn: CGRect(x: a.origin.x - a.bodyRadius * 0.95, y: engine.groundY - 8,
                                   width: a.bodyRadius * 1.9, height: 14)),
            with: .color(.black.opacity(0.35))
        )

        // Phase-2 aura: pulsing ring behind the character.
        if engine.phaseTwo {
            let pulse = 1 + 0.05 * sin(engine.time * 6)
            let auraRect = CGRect(x: a.origin.x - a.bodyRadius * pulse, y: a.origin.y - a.bodyRadius * 1.4 * pulse,
                                  width: a.bodyRadius * 2 * pulse, height: a.bodyRadius * 2.8 * pulse)
            context.stroke(
                Path(ellipseIn: auraRect),
                with: .color(accent.opacity(0.35)),
                lineWidth: 3
            )
        }

        // Pose for the current state.
        var pose = currentPose(engine)
        pose.scale = a.scale
        pose.thickness = a.thickness

        var tint: Color? = Color(hex: boss.bodyColor)
        if engine.flashBoss > 0 { tint = .white }

        // Halo-style backdrops (drawn behind the body).
        drawBackdrop(&context, engine: engine, a: a, pose: pose)

        StickmanRenderer.draw(&context, pose: pose, hipAt: a.origin, mirror: a.mirror, tint: tint)

        // Held props / face details (drawn on top).
        drawProps(&context, engine: engine, a: a, pose: pose)

        // Dizzy stars while stunned.
        if engine.bossStunTimer > 0 {
            let head = mappedPoint(.headCenter, pose: pose, a: a)
            for i in 0..<3 {
                let ang = engine.time * 4 + CGFloat(i) / 3 * 2 * .pi
                let p = CGPoint(x: head.x + cos(ang) * 34, y: head.y - 26 + sin(ang) * 10)
                let r: CGFloat = 4
                context.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                             with: .color(Color(hex: 0xF5C451)))
            }
        }
    }

    // MARK: Pose selection

    private static func currentPose(_ engine: BattleEngine) -> StickmanPose {
        let boss = engine.boss
        let idle = idlePose(boss)
        let kind = engine.currentAttack?.kind

        if engine.bossStunTimer > 0 {
            var p = stunPose()
            p.bodyRotation += sin(engine.time * 12) * 0.06
            return p
        }

        switch engine.bossState {
        case .telegraph:
            guard let kind else { return idle }
            let telegraph = (engine.currentAttack?.telegraph ?? 1) / (engine.phaseTwo ? 1.35 : 1)
            let progress = 1 - min(1, engine.bossTimer / max(0.001, CGFloat(telegraph)))
            return blend(idle, windupPose(kind), t: progress)

        case .attack:
            return attackPose(kind ?? .melee)

        case .recover:
            return blend(attackPose(kind ?? .melee), idle, t: 0.55)

        case .idle:
            // Breathing idle.
            var p = idle
            p.bodyRotation += sin(engine.time * 2.2) * 0.02
            return p
        }
    }

    private static func idlePose(_ boss: BossDefinition) -> StickmanPose {
        let angles: [(Bone, CGFloat)]
        switch boss.id {
        case "earth":
            // Bulky, hunched, wide stance.
            angles = [
                (.torso, .pi + 0.12),
                (.leftUpperArm, 0.5), (.leftForearm, 0.75),
                (.rightUpperArm, -0.5), (.rightForearm, -0.75),
                (.leftThigh, 0.3), (.leftShin, 0.38),
                (.rightThigh, -0.3), (.rightShin, -0.38),
            ]
        case "mars":
            // Slim duelist, spear hand forward.
            angles = [
                (.torso, .pi + 0.05),
                (.rightUpperArm, -0.6), (.rightForearm, -1.0),
                (.leftUpperArm, 0.45), (.leftForearm, 0.7),
                (.leftThigh, 0.16), (.leftShin, 0.22),
                (.rightThigh, -0.16), (.rightShin, -0.22),
            ]
        default:
            // Radiant overlord, arms spread.
            angles = [
                (.torso, .pi),
                (.leftUpperArm, 0.95), (.leftForearm, 0.35),
                (.rightUpperArm, -0.95), (.rightForearm, -0.35),
                (.leftThigh, 0.18), (.leftShin, 0.26),
                (.rightThigh, -0.18), (.rightShin, -0.26),
            ]
        }
        return PoseTemplate.pose(angles: PoseTemplate.angles(angles))
    }

    private static func windupPose(_ kind: BossAttackKind) -> StickmanPose {
        let angles: [(Bone, CGFloat)]
        switch kind {
        case .projectileLob:
            angles = [
                (.rightUpperArm, -2.5), (.rightForearm, -2.3),
                (.leftUpperArm, 0.8), (.leftForearm, 0.9),
                (.torso, .pi + 0.05),
            ]
        case .groundShock:
            angles = [
                (.leftUpperArm, .pi - 0.3), (.leftForearm, 0.15),
                (.rightUpperArm, -.pi + 0.3), (.rightForearm, -0.15),
                (.torso, .pi + 0.05),
            ]
        case .charge:
            angles = [
                (.torso, .pi + 0.6),
                (.leftUpperArm, 1.0), (.leftForearm, 1.1),
                (.rightUpperArm, 1.0), (.rightForearm, 1.1),
                (.leftThigh, -0.9), (.leftShin, 0.5),
                (.rightThigh, 0.7), (.rightShin, -0.5),
            ]
        case .flare:
            angles = [
                (.leftUpperArm, .pi - 0.25), (.leftForearm, 0.2),
                (.rightUpperArm, -.pi + 0.25), (.rightForearm, -0.2),
                (.torso, .pi),
            ]
        case .fan:
            angles = [
                (.leftUpperArm, 1.57), (.leftForearm, 0),
                (.rightUpperArm, -1.57), (.rightForearm, 0),
                (.torso, .pi),
            ]
        case .melee:
            angles = [
                (.rightUpperArm, -2.2), (.rightForearm, -2.4),
                (.leftUpperArm, 0.9), (.leftForearm, 1.0),
                (.torso, .pi + 0.15),
                (.leftThigh, 0.3), (.leftShin, 0.4),
                (.rightThigh, -0.3), (.rightShin, -0.4),
            ]
        }
        return PoseTemplate.pose(angles: PoseTemplate.angles(angles))
    }

    private static func attackPose(_ kind: BossAttackKind) -> StickmanPose {
        let angles: [(Bone, CGFloat)]
        switch kind {
        case .projectileLob:
            angles = [
                (.rightUpperArm, -1.5), (.rightForearm, -1.5),
                (.leftUpperArm, 0.9), (.leftForearm, 1.0),
                (.torso, .pi + 0.2),
            ]
        case .groundShock:
            angles = [
                (.leftUpperArm, 0.45), (.leftForearm, 0.55),
                (.rightUpperArm, -0.45), (.rightForearm, -0.55),
                (.torso, .pi + 0.25),
                (.leftThigh, 0.5), (.leftShin, 0.65),
                (.rightThigh, -0.5), (.rightShin, -0.65),
            ]
        case .charge:
            angles = [
                (.torso, .pi + 0.65),
                (.leftUpperArm, 1.1), (.leftForearm, 1.2),
                (.rightUpperArm, 1.1), (.rightForearm, 1.2),
                (.leftThigh, -1.0), (.leftShin, 0.4),
                (.rightThigh, 0.8), (.rightShin, -0.6),
            ]
        case .flare:
            angles = [
                (.leftUpperArm, .pi - 0.15), (.leftForearm, 0.1),
                (.rightUpperArm, -.pi + 0.15), (.rightForearm, -0.1),
                (.torso, .pi - 0.05),
            ]
        case .fan:
            angles = [
                (.leftUpperArm, 1.57), (.leftForearm, 0),
                (.rightUpperArm, -1.57), (.rightForearm, 0),
                (.torso, .pi + 0.1),
            ]
        case .melee:
            angles = [
                (.rightUpperArm, -0.9), (.rightForearm, -1.6),
                (.leftUpperArm, 1.0), (.leftForearm, 1.1),
                (.torso, .pi + 0.3),
                (.leftThigh, 0.55), (.leftShin, 0.7),
                (.rightThigh, -0.55), (.rightShin, -0.7),
            ]
        }
        return PoseTemplate.pose(angles: PoseTemplate.angles(angles))
    }

    private static func stunPose() -> StickmanPose {
        PoseTemplate.pose(angles: PoseTemplate.angles([
            (.torso, .pi - 0.18),
            (.leftUpperArm, 0.25), (.leftForearm, 0.55),
            (.rightUpperArm, -0.25), (.rightForearm, -0.55),
            (.leftThigh, 0.12), (.leftShin, 0.2),
            (.rightThigh, -0.12), (.rightShin, -0.2),
        ]))
    }

    private static func blend(_ a: StickmanPose, _ b: StickmanPose, t: CGFloat) -> StickmanPose {
        var p = a
        var angles: [Bone: CGFloat] = [:]
        for bone in Bone.allCases {
            let va = a.angles[bone] ?? 0
            let vb = b.angles[bone] ?? 0
            angles[bone] = va + (vb - va) * t
        }
        p.angles = angles
        p.bodyRotation = a.bodyRotation + (b.bodyRotation - a.bodyRotation) * t
        p.root = CGPoint(x: a.root.x + (b.root.x - a.root.x) * t,
                         y: a.root.y + (b.root.y - a.root.y) * t)
        return p
    }

    // MARK: Joint mapping

    private enum MappedPoint {
        case headCenter
        case rightHand
        case neck
        case hip
    }

    /// Maps a pose-space point to screen space (same transform as the renderer).
    private static func mappedPoint(_ which: MappedPoint, pose: StickmanPose, a: Anchor) -> CGPoint {
        let joints = StickmanKinematics.resolve(pose)
        let p: CGPoint
        switch which {
        case .headCenter: p = StickmanKinematics.headCircle(for: pose).center
        case .rightHand: p = joints[.rightHand] ?? pose.root
        case .neck: p = joints[.neck] ?? pose.root
        case .hip: p = pose.root
        }
        let dx = (p.x - pose.root.x) * (a.mirror ? -1 : 1) * pose.scale
        let dy = (p.y - pose.root.y) * pose.scale
        return CGPoint(x: a.origin.x + dx, y: a.origin.y + dy)
    }

    // MARK: Backdrops & props

    private static func drawBackdrop(_ context: inout GraphicsContext, engine: BattleEngine, a: Anchor, pose: StickmanPose) {
        let accent = Color(hex: engine.boss.accentColor)
        let head = mappedPoint(.headCenter, pose: pose, a: a)
        let headR = 11 * a.scale

        switch engine.boss.id {
        case "sun":
            // Halo ring + slowly rotating rays behind the head.
            context.stroke(
                Path(ellipseIn: CGRect(x: head.x - headR * 1.7, y: head.y - headR * 1.7,
                                       width: headR * 3.4, height: headR * 3.4)),
                with: .color(accent.opacity(0.85)),
                lineWidth: 3.5
            )
            for i in 0..<8 {
                let ang = CGFloat(i) / 8 * 2 * .pi + engine.time * 0.8
                let r1 = headR * 2.0
                let r2 = headR * 2.7
                var ray = Path()
                ray.move(to: CGPoint(x: head.x + cos(ang) * r1, y: head.y + sin(ang) * r1))
                ray.addLine(to: CGPoint(x: head.x + cos(ang) * r2, y: head.y + sin(ang) * r2))
                context.stroke(ray, with: .color(accent.opacity(0.6)), lineWidth: 2.5)
            }
            // Solar flare glow.
            if engine.currentAttack?.kind == .flare && (engine.bossState == .telegraph || engine.bossState == .attack) {
                let glow = CGRect(x: a.origin.x - 120, y: a.origin.y - 150, width: 240, height: 240)
                context.fill(
                    Path(ellipseIn: glow),
                    with: .radialGradient(Gradient(colors: [accent.opacity(0.4), .clear]),
                                          center: CGPoint(x: glow.midX, y: glow.midY),
                                          startRadius: 10, endRadius: 130)
                )
            }
        default:
            break
        }
    }

    private static func drawProps(_ context: inout GraphicsContext, engine: BattleEngine, a: Anchor, pose: StickmanPose) {
        let accent = Color(hex: engine.boss.accentColor)
        let head = mappedPoint(.headCenter, pose: pose, a: a)
        let headR = 11 * a.scale
        let hand = mappedPoint(.rightHand, pose: pose, a: a)
        let neck = mappedPoint(.neck, pose: pose, a: a)
        let hip = mappedPoint(.hip, pose: pose, a: a)

        switch engine.boss.id {
        case "earth":
            // Rocky plating: crater dots along the torso.
            for t in stride(from: CGFloat(0.3), through: CGFloat(0.75), by: 0.45) {
                let c = CGPoint(x: neck.x + (hip.x - neck.x) * t + 8,
                                y: neck.y + (hip.y - neck.y) * t)
                context.fill(
                    Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)),
                    with: .color(accent.opacity(0.5))
                )
            }
            // Boulder while lobbing.
            if let kind = engine.currentAttack?.kind, kind == .projectileLob,
               engine.bossState == .telegraph || engine.bossState == .attack {
                let r = 13 * a.scale
                context.fill(
                    Path(ellipseIn: CGRect(x: hand.x - r, y: hand.y - r, width: r * 2, height: r * 2)),
                    with: .color(Color(hex: 0x8A6A4A))
                )
            }

        case "mars":
            // Horns.
            for side in [-1.0, 1.0] {
                var horn = Path()
                let bx = head.x + CGFloat(side) * headR * 0.55
                horn.move(to: CGPoint(x: bx, y: head.y - headR * 0.7))
                horn.addLine(to: CGPoint(x: bx + CGFloat(side) * 7, y: head.y - headR * 1.7))
                horn.addLine(to: CGPoint(x: bx + CGFloat(side) * 13, y: head.y - headR * 0.55))
                horn.closeSubpath()
                context.fill(horn, with: .color(accent))
            }
            // Spear along the right forearm direction.
            let joints = StickmanKinematics.resolve(pose)
            if let elbow = joints[.rightElbow], let handPose = joints[.rightHand] {
                let dirX = (handPose.x - elbow.x) * (a.mirror ? -1 : 1)
                let dirY = handPose.y - elbow.y
                let len = max(1, hypot(dirX, dirY))
                let ux = dirX / len, uy = dirY / len
                var spear = Path()
                spear.move(to: CGPoint(x: hand.x - ux * 46 * a.scale, y: hand.y - uy * 46 * a.scale))
                spear.addLine(to: CGPoint(x: hand.x + ux * 66 * a.scale, y: hand.y + uy * 66 * a.scale))
                context.stroke(spear, with: .color(accent), lineWidth: 4)
                // Spear tip.
                var tip = Path()
                let tipX = hand.x + ux * 78 * a.scale
                let tipY = hand.y + uy * 78 * a.scale
                tip.move(to: CGPoint(x: tipX + ux * 14, y: tipY + uy * 14))
                tip.addLine(to: CGPoint(x: tipX - uy * 6, y: tipY + ux * 6))
                tip.addLine(to: CGPoint(x: tipX + uy * 6, y: tipY - ux * 6))
                tip.closeSubpath()
                context.fill(tip, with: .color(accent))
            }

        default:
            // Crown spikes above the halo.
            for i in -1...1 {
                let x = head.x + CGFloat(i) * headR * 0.8
                var spike = Path()
                spike.move(to: CGPoint(x: x - 3.5, y: head.y - headR * 1.75))
                spike.addLine(to: CGPoint(x: x, y: head.y - headR * (i == 0 ? 2.9 : 2.4)))
                spike.addLine(to: CGPoint(x: x + 3.5, y: head.y - headR * 1.75))
                spike.closeSubpath()
                context.fill(spike, with: .color(accent))
            }
        }
    }
}
