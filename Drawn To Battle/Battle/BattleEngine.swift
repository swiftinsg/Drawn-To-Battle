import SwiftUI
import Combine
import CoreGraphics
import UIKit

// MARK: - Haptics helper

enum Haptics {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}

// MARK: - Battle data types

struct BattleInput {
    var move: CGVector = .zero       // -1...1 both axes (joystick)
    var attackQueued = false
    var blockHeld = false
    var ultimateQueued = false
    var dodgeQueued = false
}

enum BattleResult: Equatable {
    case victory
    case defeat
}

struct Projectile {
    var pos: CGPoint
    var vel: CGVector
    var radius: CGFloat
    var damage: Double
    var gravity: CGFloat
    var ground: Bool          // travels along the floor (must be jumped)
    var life: CGFloat = 4
    var color: Color
    /// A parried projectile flips ownership and can damage the boss.
    var friendly = false
}

struct Floater {
    var text: String
    var pos: CGPoint
    var life: CGFloat = 0.9
    var color: Color = .white
    var big = false
}

struct Particle {
    var pos: CGPoint
    var vel: CGVector
    var life: CGFloat
    var maxLife: CGFloat
    var size: CGFloat
    var color: Color
    var gravity: CGFloat = 0
}

/// A fading ghost of the player, drawn during attacks, dodges and ultimates.
struct Afterimage {
    var pose: StickmanPose
    var hip: CGPoint
    var mirror: Bool
    var life: CGFloat
    var maxLife: CGFloat
}

// MARK: - Engine

/// Runs the whole boss fight simulation. Updated on a Timer from
/// BattleView; HUD-relevant values are published. All mutating work happens
/// here — never during view rendering.
final class BattleEngine: ObservableObject {
    // Config
    let boss: BossDefinition
    let project: AnimationProject
    let analysis: AnalysisResult
    let blueprintMult: Double
    let arena: CGSize
    let fps: Double

    // HUD (published)
    @Published var playerHP: Double = 100
    @Published var bossHP: Double
    @Published var ultMeter: Double = 0
    @Published var phaseTwo = false
    @Published var result: BattleResult?
    @Published var attackCharge: Double = 0     // 0...1 attack animation progress
    @Published var currentAttackName: String = ""
    @Published var comboCount = 0
    @Published var bossStagger: Double = 0

    // Simulation state
    var input = BattleInput()
    var playerPos: CGPoint            // hip position
    var playerVel = CGVector.zero
    var grounded = true
    var facing: CGFloat = 1           // 1 faces right, -1 faces left
    var attackActive = false
    var attackTime: CGFloat = 0
    var attackDamageDone = false
    var attackCooldown: CGFloat = 0
    var currentIsUltimate = false
    var hurtTimer: CGFloat = 0
    var invulnTimer: CGFloat = 0
    var runCycle: CGFloat = 0
    var flashPlayer: CGFloat = 0
    var flashBoss: CGFloat = 0
    var blockActive = false
    var blockStart: CGFloat = -10     // time the current block began (parry window)
    var dodgeActive = false
    var dodgeTimer: CGFloat = 0
    var dodgeDir: CGFloat = -1
    var dodgeCooldown: CGFloat = 0

    // Combat feel
    var hitStop: CGFloat = 0          // world freeze on big impacts
    var shake: CGFloat = 0            // screen shake amplitude
    var comboTimer: CGFloat = 0
    var afterimageTimer: CGFloat = 0

    // Boss
    var bossX: CGFloat
    var bossState: BossPhase = .idle
    var bossTimer: CGFloat = 1.4
    var currentAttack: BossAttackDef?
    var lastAttackName: String = ""
    var charging = false
    var chargeVel: CGFloat = 0
    var chargeTouchedPlayer = false
    var flareTimer: CGFloat = 0
    var bossStaggerMax: Double = 100
    var bossStunTimer: CGFloat = 0
    var bossFlashDmg: CGFloat = 0
    var projectiles: [Projectile] = []
    var floaters: [Floater] = []
    var particles: [Particle] = []
    var afterimages: [Afterimage] = []
    var lastDate: Date?
    var time: CGFloat = 0

    // Battle stats (result overlay)
    var damageDealt = 0.0
    var damageTaken = 0.0
    var parries = 0
    var maxCombo = 0
    var battleTime: Double = 0

    enum BossPhase { case idle, telegraph, attack, recover }

    var groundY: CGFloat { arena.height - 185 }
    var bossHPMax: Double { boss.hp }

    // MARK: Init

    init(boss: BossDefinition, project: AnimationProject, analysis: AnalysisResult,
         blueprintMult: Double, arena: CGSize) {
        self.boss = boss
        self.project = project
        self.analysis = analysis
        self.blueprintMult = blueprintMult
        self.arena = arena
        self.fps = Double(max(1, project.fps))
        self.bossHP = boss.hp
        self.bossX = arena.width - 260
        self.playerPos = CGPoint(x: 170, y: arena.height - 185 - 45)
    }

    // MARK: Simulation loop (runs outside view updates so @Published
    // mutations never happen during rendering).

    private var simTimer: Timer?

    func startLoop() {
        guard simTimer == nil else { return }
        lastDate = nil
        simTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            self?.tick(Date())
        }
    }

    func stopLoop() {
        simTimer?.invalidate()
        simTimer = nil
    }

    // MARK: Reset (retry)

    func reset() {
        playerHP = 100
        bossHP = boss.hp
        ultMeter = 0
        phaseTwo = false
        result = nil
        attackCharge = 0
        currentAttackName = ""
        comboCount = 0
        comboTimer = 0
        bossStagger = 0
        bossStunTimer = 0
        playerPos = CGPoint(x: 170, y: groundY - 45)
        playerVel = .zero
        grounded = true
        facing = 1
        attackActive = false
        attackTime = 0
        attackDamageDone = false
        attackCooldown = 0
        currentIsUltimate = false
        hurtTimer = 0
        invulnTimer = 0
        runCycle = 0
        flashPlayer = 0
        flashBoss = 0
        blockActive = false
        blockStart = -10
        dodgeActive = false
        dodgeTimer = 0
        dodgeCooldown = 0
        hitStop = 0
        shake = 0
        afterimageTimer = 0
        bossX = arena.width - 260
        bossState = .idle
        bossTimer = 1.4
        currentAttack = nil
        lastAttackName = ""
        charging = false
        chargeVel = 0
        chargeTouchedPlayer = false
        flareTimer = 0
        projectiles = []
        floaters = []
        particles = []
        afterimages = []
        lastDate = nil
        damageDealt = 0
        damageTaken = 0
        parries = 0
        maxCombo = 0
        battleTime = 0
        input = BattleInput()
    }

    // MARK: Tick

    func tick(_ now: Date) {
        guard result == nil else { return }
        let dt = min(max(now.timeIntervalSince(lastDate ?? now), 0), 0.05)
        lastDate = now
        time += CGFloat(dt)
        let d = CGFloat(dt)

        // Hit-stop: the world freezes for a beat on big impacts.
        if hitStop > 0 {
            hitStop = max(0, hitStop - d)
            updateFloaters(d * 0.35)
            updateParticles(d * 0.2)
            return
        }

        if !phaseTwo && bossHP <= bossHPMax * 0.6 {
            phaseTwo = true
            floaters.append(Floater(text: boss.bossName + " ENRAGES!",
                                    pos: CGPoint(x: bossX, y: groundY - 190),
                                    color: Color(hex: boss.accentColor), big: true))
            shake = max(shake, 12)
            Haptics.warning()
        }

        updatePlayer(d)
        updateCombo(d)
        updateAttack(d)
        updateBoss(d)
        updateProjectiles(d)
        updateParticles(d)
        updateAfterimages(d)
        updateFloaters(d)
        shake = max(0, shake - d * 26)
        flashPlayer = max(0, flashPlayer - d)
        flashBoss = max(0, flashBoss - d)
    }

    // MARK: Player

    private func updatePlayer(_ d: CGFloat) {
        invulnTimer = max(0, invulnTimer - d)
        hurtTimer = max(0, hurtTimer - d)
        dodgeCooldown = max(0, dodgeCooldown - d)
        attackCooldown = max(0, attackCooldown - d)

        // Once the strike has landed the player can move, block and dodge again,
        // even while the rest of a long animation finishes playing.
        let canControl = (!attackActive || attackDamageDone) && hurtTimer <= 0
        blockActive = input.blockHeld && canControl && !dodgeActive
        if blockActive && blockStart < 0 { blockStart = time }
        if !input.blockHeld { blockStart = -10 }

        // Dodge roll (cancels a finished attack too).
        if input.dodgeQueued {
            input.dodgeQueued = false
            let canCancelAttack = attackActive && attackDamageDone
            if (canControl || canCancelAttack) && dodgeCooldown <= 0 {
                if canCancelAttack { attackActive = false }
                startDodge()
            }
        }

        if dodgeActive {
            dodgeTimer -= d
            invulnTimer = max(invulnTimer, dodgeTimer + 0.02)
            playerVel.dx = dodgeDir * 520
            afterimageTimer -= d
            if afterimageTimer <= 0 { afterimageTimer = 0.035; spawnAfterimage() }
            if dodgeTimer <= 0 {
                dodgeActive = false
                playerVel.dx *= 0.3
            }
        } else if canControl {
            let vx = input.move.dx * 260
            playerVel.dx = vx
            if input.move.dx > 0.1 {
                facing = 1
            } else if input.move.dx < -0.1 {
                facing = -1
            }
            if input.move.dy < -0.5 && grounded {
                playerVel.dy = -560
                grounded = false
                spawnDust(count: 6)
            }
            if abs(input.move.dx) > 0.15 && grounded {
                runCycle += d * 11
                // Footstep dust while sprinting.
                if Int(runCycle * 2) % 4 == 0 { spawnDust(count: 1) }
            }
        } else if !attackActive {
            playerVel.dx *= 0.8
        }

        // Attack motion trails.
        if attackActive {
            afterimageTimer -= d
            if afterimageTimer <= 0 { afterimageTimer = 0.04; spawnAfterimage() }
        }

        // Gravity / floor.
        let wasAirborne = !grounded
        playerVel.dy += 1300 * d
        playerPos.x += playerVel.dx * d
        playerPos.y += playerVel.dy * d
        let floorHip = groundY - 45
        if playerPos.y >= floorHip {
            if wasAirborne { spawnDust(count: 5) }
            playerPos.y = floorHip
            playerVel.dy = 0
            grounded = true
        }
        playerPos.x = min(max(50, playerPos.x), arena.width - 50)
    }

    private func startDodge() {
        dodgeActive = true
        dodgeTimer = 0.32
        dodgeCooldown = 1.1
        dodgeDir = abs(input.move.dx) > 0.2 ? (input.move.dx > 0 ? 1 : -1) : facing
        invulnTimer = max(invulnTimer, 0.34)
        spawnDust(count: 8)
        Haptics.light()
    }

    private func updateCombo(_ d: CGFloat) {
        if comboTimer > 0 {
            comboTimer -= d
            if comboTimer <= 0 && comboCount > 0 {
                comboCount = 0
            }
        }
    }

    // MARK: Attack

    private func updateAttack(_ d: CGFloat) {
        if input.attackQueued {
            input.attackQueued = false
            if !attackActive && hurtTimer <= 0 && !blockActive && attackCooldown <= 0 {
                startAttack(ultimate: false)
            }
        }
        if input.ultimateQueued {
            input.ultimateQueued = false
            if ultMeter >= 100 && !attackActive && hurtTimer <= 0 && !blockActive {
                ultMeter = 0
                startAttack(ultimate: true)
            }
        }

        guard attackActive else {
            attackCharge = 0
            return
        }
        // Ultimates play faster and hit harder.
        let speed: CGFloat = currentIsUltimate ? 1.6 : 1
        attackTime += d * speed
        attackCharge = min(1, attackTime / attackDuration)
        let idx = min(project.frames.count - 1, Int(attackTime * playbackFPS))

        if !attackDamageDone && idx >= analysis.strikeIndex {
            attackDamageDone = true
            applyStrike(ultimate: currentIsUltimate)
        }
        if attackTime >= attackDuration {
            attackActive = false
            attackCooldown = 0.18
        }
    }

    /// Long hand-drawn animations still need to resolve quickly so the boss
    /// can't attack while the player is locked in a 2-second move.
    private static let maxAttackDuration: CGFloat = 0.6

    var attackDuration: CGFloat {
        let natural = CGFloat(project.frames.count) / CGFloat(fps)
        return min(natural, Self.maxAttackDuration)
    }

    /// Frames are remapped onto the capped duration so the whole animation
    /// still plays, just faster for oversized frame counts.
    private var playbackFPS: CGFloat {
        guard attackDuration > 0 else { return CGFloat(fps) }
        return CGFloat(project.frames.count) / attackDuration
    }

    private func startAttack(ultimate: Bool) {
        attackActive = true
        attackTime = 0
        attackDamageDone = false
        currentIsUltimate = ultimate
        facing = bossX > playerPos.x ? 1 : -1
    }

    private func applyStrike(ultimate: Bool) {
        let reach: CGFloat = 155
        if abs(bossX - playerPos.x) > reach {
            floaters.append(Floater(text: "MISS",
                                    pos: CGPoint(x: playerPos.x + 60 * (facing == 1 ? 1 : -1), y: playerPos.y - 90)))
            return
        }

        // Animation quality IS the weapon: a sloppy 0-power swing does ~5,
        // a perfect 100-power swing does ~40 before rarity/combo/stun.
        var dmg = 5 + analysis.power / 100 * 35
        let techMatch = analysis.techniques.contains(boss.requiredTechnique)
        if !techMatch {
            dmg *= 0.18
            floaters.append(Floater(text: "MISMATCH — needs \(boss.requiredTechnique.label)",
                                    pos: CGPoint(x: bossX, y: groundY - 200),
                                    color: Color(hex: 0xE86A6A)))
        }
        dmg *= blueprintMult
        // Combo bonus: each consecutive hit adds +4%, up to +40%.
        dmg *= 1 + min(Double(comboCount), 10) * 0.04
        if bossStunTimer > 0 { dmg *= 1.5 }
        if ultimate { dmg *= 2.3 }

        bossHP = max(0, bossHP - dmg)
        damageDealt += dmg

        // Combo.
        comboCount += 1
        maxCombo = max(maxCombo, comboCount)
        comboTimer = 2.5

        // Stagger build.
        bossStagger = min(bossStaggerMax, bossStagger + 9 + analysis.power * 0.09)
        maybeStaggerBreak()

        // Juice.
        flashBoss = 0.22
        hitStop = ultimate ? 0.12 : 0.055
        shake = max(shake, ultimate ? 14 : 7)
        if !ultimate { ultMeter = min(100, ultMeter + 6) }

        let contact = CGPoint(x: bossX + (playerPos.x < bossX ? 46 : -46), y: playerPos.y - 30)
        spawnBurst(at: contact, count: ultimate ? 26 : 12,
                   color: ultimate ? Color(hex: 0xF5C451) : Color(hex: boss.accentColor),
                   speed: ultimate ? 420 : 260)
        if ultimate {
            spawnBurst(at: contact, count: 14, color: .white, speed: 300)
        }

        floaters.append(Floater(
            text: ultimate ? "-\(Int(dmg)) ULT!" : "-\(Int(dmg))",
            pos: CGPoint(x: bossX, y: groundY - 160),
            color: ultimate ? Color(hex: 0xF5C451) : (techMatch ? .white : Color(hex: 0xE86A6A)),
            big: ultimate || (bossStunTimer > 0)
        ))
        if bossStunTimer > 0 {
            floaters.append(Floater(text: "STUN BREAK!",
                                    pos: CGPoint(x: bossX, y: groundY - 200),
                                    color: Color(hex: 0xA86CFF)))
        }
        Haptics.medium()
        if ultimate { Haptics.heavy() }

        if bossHP <= 0 { finish(.victory) }
    }

    // MARK: Stagger / stun

    private func maybeStaggerBreak() {
        guard bossStagger >= bossStaggerMax, bossStunTimer <= 0 else { return }
        bossStagger = 0
        bossStunTimer = 2.4
        charging = false
        chargeVel = 0
        bossState = .idle
        bossTimer = max(bossTimer, 1.0)
        hitStop = 0.16
        shake = max(shake, 15)
        floaters.append(Floater(text: "STAGGERED!",
                                pos: CGPoint(x: bossX, y: groundY - 220),
                                color: Color(hex: 0xA86CFF), big: true))
        spawnBurst(at: CGPoint(x: bossX, y: groundY - 110), count: 22,
                   color: Color(hex: 0xA86CFF), speed: 380)
        Haptics.success()
    }

    // MARK: Boss

    private func updateBoss(_ d: CGFloat) {
        // Stunned: frozen and wide open.
        if bossStunTimer > 0 {
            bossStunTimer -= d
            if bossStunTimer <= 0 {
                floaters.append(Floater(text: "RECOVERED",
                                        pos: CGPoint(x: bossX, y: groundY - 200),
                                        color: .white.opacity(0.7)))
            }
            return
        }

        let speedMul: CGFloat = phaseTwo ? 1.5 : 1

        switch bossState {
        case .idle:
            // Keep a natural fighting distance so the boss doesn't
            // stand on top of the player or the control buttons.
            let dist = abs(playerPos.x - bossX)
            if dist > 380 {
                bossX += facingSign() * 75 * d
            } else if dist < 210 {
                bossX -= facingSign() * 55 * d
            }
            bossX = min(max(120, bossX), arena.width - 90)

            bossTimer -= d
            if bossTimer <= 0 {
                currentAttack = chooseAttack()
                lastAttackName = currentAttack?.name ?? ""
                bossState = .telegraph
                bossTimer = (currentAttack?.telegraph ?? 1) / speedMul
                currentAttackName = currentAttack?.name ?? ""
            }

        case .telegraph:
            bossTimer -= d
            if bossTimer <= 0 { executeAttack() }

        case .attack:
            bossTimer -= d
            switch currentAttack?.kind {
            case .charge:
                bossX += chargeVel * d
                bossX = min(max(120, bossX), arena.width - 80)
                if abs(bossX - playerPos.x) < 75 && !chargeTouchedPlayer {
                    chargeTouchedPlayer = true
                    damagePlayer(currentAttack?.damage ?? 15)
                }
                if bossTimer <= 0 {
                    if !chargeTouchedPlayer && (bossX <= 130 || bossX >= arena.width - 90) {
                        punishWindow()
                    } else {
                        endAttack()
                    }
                }

            case .flare:
                flareTimer -= d
                if flareTimer <= 0 {
                    damagePlayer(currentAttack?.damage ?? 16)
                    endAttack()
                }

            case .melee:
                // Lunge toward the player during the swing.
                bossX += facingSign() * 240 * d
                if bossTimer <= 0 {
                    if abs(bossX - playerPos.x) < 160 {
                        damagePlayer(currentAttack?.damage ?? 15)
                        endAttack()
                    } else {
                        punishWindow()
                    }
                }

            default:
                if bossTimer <= 0 { endAttack() }
            }

        case .recover:
            bossTimer -= d
            if bossTimer <= 0 {
                bossState = .idle
                bossTimer = (phaseTwo ? 0.5 : 0.85)
            }
        }
    }

    /// Attack choice adapts to distance and avoids repeating itself.
    private func chooseAttack() -> BossAttackDef {
        let dist = abs(playerPos.x - bossX)
        let close = boss.attacks.filter { $0.kind == .melee || $0.kind == .charge }
        let ranged = boss.attacks.filter { $0.kind != .melee && $0.kind != .charge }
        var pool = dist < 280 ? (close.isEmpty ? boss.attacks : close)
                              : (ranged.isEmpty ? boss.attacks : ranged)
        if pool.count > 1 {
            let fresh = pool.filter { $0.name != lastAttackName }
            if !fresh.isEmpty { pool = fresh }
        }
        return pool.randomElement() ?? boss.attacks[0]
    }

    /// The boss whiffed — a longer recovery the player can punish.
    private func punishWindow() {
        charging = false
        bossState = .recover
        bossTimer = phaseTwo ? 0.6 : 0.85
        floaters.append(Floater(text: "STRIKE NOW!",
                                pos: CGPoint(x: bossX, y: groundY - 210),
                                color: Color(hex: 0xF5C451), big: true))
    }

    private func executeAttack() {
        guard let attack = currentAttack else { bossState = .recover; bossTimer = 0.5; return }
        bossState = .attack
        attackDamageDone = false
        chargeTouchedPlayer = false

        switch attack.kind {
        case .projectileLob:
            let dx = playerPos.x + playerVel.dx * 0.25 - bossX
            let dy = (playerPos.y - 60) - (groundY - 110)
            let len = max(1, CGFloat(sqrt(Double(dx * dx + dy * dy))))
            projectiles.append(Projectile(
                pos: CGPoint(x: bossX - 40, y: groundY - 110),
                vel: CGVector(dx: dx / len * 430, dy: dy / len * 430 - 200),
                radius: 14, damage: attack.damage, gravity: 800, ground: false,
                color: Color(hex: 0x8A6A4A)
            ))
            bossTimer = 0.5

        case .groundShock:
            projectiles.append(Projectile(
                pos: CGPoint(x: bossX - 60, y: groundY - 14),
                vel: CGVector(dx: -360, dy: 0),
                radius: 18, damage: attack.damage, gravity: 0, ground: true,
                color: Color(hex: boss.accentColor)
            ))
            shake = max(shake, 6)
            bossTimer = 0.6

        case .charge:
            charging = true
            chargeVel = (playerPos.x > bossX ? 1 : -1) * 540
            bossTimer = 0.55
            spawnDustAt(CGPoint(x: bossX, y: groundY - 6), count: 8)

        case .flare:
            flareTimer = 0.35
            bossTimer = 0.4

        case .fan:
            let base = atan2((playerPos.y - 40) - (groundY - 110), playerPos.x - bossX)
            for spread in [-0.38, 0, 0.38] {
                let a = base + spread
                projectiles.append(Projectile(
                    pos: CGPoint(x: bossX - 40, y: groundY - 110),
                    vel: CGVector(dx: cos(a) * 380, dy: sin(a) * 380),
                    radius: 10, damage: attack.damage, gravity: 0, ground: false,
                    color: Color(hex: boss.accentColor)
                ))
            }
            bossTimer = 0.5

        case .melee:
            bossTimer = 0.45
        }
    }

    private func endAttack() {
        charging = false
        bossState = .recover
        bossTimer = phaseTwo ? 0.32 : 0.55
    }

    private func facingSign() -> CGFloat { playerPos.x > bossX ? 1 : -1 }

    // MARK: Damage to player

    /// Central damage entry point. Handles dodge i-frames, blocking,
    /// parries (block pressed within 0.22 s before impact) and clean hits.
    private func damagePlayer(_ raw: Double) {
        if dodgeActive || invulnTimer > 0 { return }

        if blockActive {
            let blockAge = time - blockStart
            if blockAge <= 0.22 {
                parry()
                return
            }
            // Ordinary block: solid shield — the hit is fully absorbed,
            // only the follow-through registers (bursts, shake, meter).
            hurtTimer = 0.15
            flashPlayer = 0.15
            ultMeter = min(100, ultMeter + 4)
            floaters.append(Floater(text: "BLOCKED",
                                    pos: CGPoint(x: playerPos.x, y: playerPos.y - 110),
                                    color: Color(hex: 0x4C8DFF)))
            spawnBurst(at: CGPoint(x: playerPos.x + (playerPos.x < bossX ? 24 : -24), y: playerPos.y - 40),
                       count: 6, color: Color(hex: 0x4C8DFF), speed: 160)
            shake = max(shake, 4)
            Haptics.light()
            return
        }

        // Clean hit.
        invulnTimer = 0.8
        hurtTimer = 0.35
        flashPlayer = 0.3
        playerHP = max(0, playerHP - raw)
        damageTaken += raw
        ultMeter = min(100, ultMeter + 12)
        comboCount = 0
        comboTimer = 0
        shake = max(shake, 9)
        hitStop = max(hitStop, 0.05)
        spawnBurst(at: CGPoint(x: playerPos.x, y: playerPos.y - 40), count: 10,
                   color: Color(hex: 0xE86A6A), speed: 240)
        floaters.append(Floater(
            text: "-\(Int(raw))",
            pos: CGPoint(x: playerPos.x, y: playerPos.y - 130),
            color: Color(hex: 0xE86A6A)
        ))
        Haptics.heavy()
        if playerHP <= 0 { finish(.defeat) }
    }

    /// Perfect-timed block: no damage, big meter + stagger gain.
    private func parry() {
        parries += 1
        ultMeter = min(100, ultMeter + 18)
        bossStagger = min(bossStaggerMax, bossStagger + 22)
        maybeStaggerBreak()
        hitStop = max(hitStop, 0.11)
        shake = max(shake, 8)
        flashPlayer = 0.12
        floaters.append(Floater(text: "PARRY!",
                                pos: CGPoint(x: playerPos.x, y: playerPos.y - 130),
                                color: Color(hex: 0xF5C451), big: true))
        spawnBurst(at: CGPoint(x: playerPos.x, y: playerPos.y - 45), count: 14,
                   color: Color(hex: 0xF5C451), speed: 300)
        Haptics.medium()
    }

    private func finish(_ r: BattleResult) {
        battleTime = Double(time)
        result = r
        if r == .victory { Haptics.success() } else { Haptics.warning() }
    }

    // MARK: Projectiles

    private func updateProjectiles(_ d: CGFloat) {
        for i in projectiles.indices.reversed() {
            var p = projectiles[i]
            p.vel.dy += p.gravity * d
            p.pos.x += p.vel.dx * d
            if p.ground {
                p.pos.y = groundY - 14
            } else {
                p.pos.y += p.vel.dy * d
            }
            p.life -= d

            if p.friendly {
                // Parried projectile flies back at the boss.
                if abs(p.pos.x - bossX) < p.radius + 42 && abs(p.pos.y - (groundY - 100)) < p.radius + 70 {
                    let dmg = p.damage * 1.2
                    bossHP = max(0, bossHP - dmg)
                    damageDealt += dmg
                    flashBoss = 0.2
                    bossStagger = min(bossStaggerMax, bossStagger + 8)
                    maybeStaggerBreak()
                    floaters.append(Floater(text: "REFLECTED -\(Int(dmg))",
                                            pos: CGPoint(x: bossX, y: groundY - 160),
                                            color: Color(hex: 0xF5C451)))
                    spawnBurst(at: p.pos, count: 10, color: Color(hex: 0xF5C451), speed: 240)
                    projectiles.remove(at: i)
                    if bossHP <= 0 { finish(.victory) }
                    continue
                }
            } else {
                let hitRadius = p.radius + 18
                if abs(p.pos.x - playerPos.x) < hitRadius && abs(p.pos.y - playerPos.y) < hitRadius + 20 {
                    let wasBlocked = blockActive
                    damagePlayer(p.damage)
                    // Blocked or parried projectiles shatter (parry reflects a
                    // fresh friendly one for the boss).
                    if wasBlocked {
                        if time - blockStart <= 0.22 {
                            var reflected = p
                            reflected.friendly = true
                            reflected.vel = CGVector(dx: bossX > p.pos.x ? 460 : -460, dy: -60)
                            reflected.color = Color(hex: 0xF5C451)
                            projectiles[i] = reflected
                            continue
                        }
                        projectiles.remove(at: i)
                    } else {
                        projectiles.remove(at: i)
                    }
                    continue
                }
            }

            projectiles[i] = p
            if p.life <= 0 || p.pos.x < -40 || p.pos.x > arena.width + 40 || p.pos.y > arena.height + 60 {
                projectiles.remove(at: i)
            }
        }
    }

    // MARK: Effects

    private func updateParticles(_ d: CGFloat) {
        for i in particles.indices.reversed() {
            var p = particles[i]
            p.vel.dy += p.gravity * d
            p.pos.x += p.vel.dx * d
            p.pos.y += p.vel.dy * d
            p.life -= d
            if p.life <= 0 {
                particles.remove(at: i)
            } else {
                particles[i] = p
            }
        }
        if particles.count > 240 {
            particles.removeFirst(particles.count - 240)
        }
    }

    private func updateAfterimages(_ d: CGFloat) {
        for i in afterimages.indices.reversed() {
            afterimages[i].life -= d
            if afterimages[i].life <= 0 { afterimages.remove(at: i) }
        }
    }

    private func updateFloaters(_ d: CGFloat) {
        for i in floaters.indices.reversed() {
            floaters[i].life -= d
            floaters[i].pos.y -= 42 * d
            if floaters[i].life <= 0 { floaters.remove(at: i) }
        }
    }

    private func spawnAfterimage() {
        var pose = currentPoseForRender()
        pose.scale = 0.62
        pose.thickness = 7
        afterimages.append(Afterimage(
            pose: pose,
            hip: playerPos,
            mirror: facing == -1,
            life: 0.22,
            maxLife: 0.22
        ))
    }

    /// The pose the view would draw right now (shared logic with the view).
    func currentPoseForRender() -> StickmanPose {
        if attackActive {
            let idx = min(project.frames.count - 1, Int(attackTime * playbackFPS))
            return project.frames[idx].pose
        }
        if blockActive {
            return PoseTemplate.pose(angles: PoseTemplate.angles([
                (.leftUpperArm, 0.9), (.leftForearm, 1.6),
                (.rightUpperArm, -0.9), (.rightForearm, -1.6),
            ]))
        }
        if dodgeActive {
            return PoseTemplate.pose(angles: PoseTemplate.angles([
                (.torso, .pi + 0.7),
                (.leftUpperArm, -0.5), (.rightUpperArm, 0.5),
                (.leftThigh, 0.9), (.rightThigh, -0.6),
                (.leftShin, 0.6), (.rightShin, -0.4),
            ]))
        }
        if hurtTimer > 0 {
            return PoseTemplate.pose(angles: PoseTemplate.angles([
                (.torso, .pi - 0.3),
                (.leftUpperArm, 1.2), (.rightUpperArm, -1.2),
                (.leftThigh, 0.4), (.rightThigh, -0.2),
            ]))
        }
        if abs(input.move.dx) > 0.15 && grounded {
            let s = sin(runCycle)
            return PoseTemplate.pose(angles: PoseTemplate.angles([
                (.leftThigh, s * 0.65), (.leftShin, max(0, -s) * 0.8),
                (.rightThigh, -s * 0.65), (.rightShin, max(0, s) * 0.8),
                (.leftUpperArm, -s * 0.7), (.rightUpperArm, s * 0.7),
            ]))
        }
        if !grounded {
            return PoseTemplate.pose(angles: PoseTemplate.angles([
                (.leftThigh, 0.7), (.leftShin, 0.9),
                (.rightThigh, -0.4), (.rightShin, 0.5),
                (.leftUpperArm, -1.1), (.rightUpperArm, 1.1),
            ]))
        }
        return PoseTemplate.pose(angles: PoseTemplate.angles([
            (.leftUpperArm, 0.55), (.leftForearm, 0.9),
            (.rightUpperArm, -0.55), (.rightForearm, -0.9),
        ]))
    }

    // MARK: Effect spawners

    func spawnBurst(at point: CGPoint, count: Int, color: Color, speed: CGFloat) {
        for _ in 0..<count {
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let v = speed * CGFloat.random(in: 0.35...1)
            particles.append(Particle(
                pos: point,
                vel: CGVector(dx: cos(a) * v, dy: sin(a) * v - 40),
                life: CGFloat.random(in: 0.25...0.55),
                maxLife: 0.55,
                size: CGFloat.random(in: 2...5),
                color: color,
                gravity: 500
            ))
        }
    }

    private func spawnDust(count: Int) {
        spawnDustAt(CGPoint(x: playerPos.x, y: groundY - 4), count: count)
    }

    private func spawnDustAt(_ point: CGPoint, count: Int) {
        for _ in 0..<count {
            let dir = CGFloat.random(in: -1...1)
            particles.append(Particle(
                pos: CGPoint(x: point.x + CGFloat.random(in: -14...14), y: point.y),
                vel: CGVector(dx: dir * 90, dy: CGFloat.random(in: (-70)...(-10))),
                life: CGFloat.random(in: 0.25...0.45),
                maxLife: 0.45,
                size: CGFloat.random(in: 2.5...5),
                color: .white.opacity(0.35),
                gravity: 160
            ))
        }
    }
}
