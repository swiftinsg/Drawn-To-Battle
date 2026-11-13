import SwiftUI

// MARK: - Combat techniques

/// Animation techniques that can be detected in a stickman animation.
/// Each boss can only be seriously damaged by one of these.
enum CombatTechnique: String, Codable, CaseIterable, Hashable {
    case punch, kick, slam, spin, dash, smear

    var label: String { rawValue.uppercased() }

    var blurb: String {
        switch self {
        case .punch: return "A fast, extended hand strike."
        case .kick: return "A powerful extended leg strike."
        case .slam: return "Both arms raised, then brought down hard."
        case .spin: return "The whole body sweeps through a rotation."
        case .dash: return "The fighter surges across the arena."
        case .smear: return "A limb whips through a huge arc in a blink — a smear frame strike."
        }
    }
}

// MARK: - Rarity

enum Rarity: String, Codable, CaseIterable, Hashable {
    case base, common, rare, epic, mythic, legendary, elite, transcendent, omniscient

    var stars: Int {
        switch self {
        case .base: return 1
        case .common: return 2
        case .rare: return 3
        case .epic: return 4
        case .mythic: return 5
        case .legendary: return 6
        case .elite: return 7
        case .transcendent: return 8
        case .omniscient: return 9
        }
    }

    /// Damage multiplier granted by a blueprint of this rarity.
    var damageMultiplier: Double {
        switch self {
        case .base: return 1.0
        case .common: return 1.1
        case .rare: return 1.25
        case .epic: return 1.45
        case .mythic: return 1.7
        case .legendary: return 2.0
        case .elite: return 2.4
        case .transcendent: return 2.8
        case .omniscient: return 3.3
        }
    }

    /// Gacha weight (out of 100).
    var weight: Double {
        switch self {
        case .base: return 30
        case .common: return 26
        case .rare: return 18
        case .epic: return 12
        case .mythic: return 7
        case .legendary: return 4.5
        case .elite: return 1.8
        case .transcendent: return 0.6
        case .omniscient: return 0.1
        }
    }

    var color: Color {
        switch self {
        case .base: return Color(hex: 0xC7CBD4)
        case .common: return Color(hex: 0x35C759)
        case .rare: return Color(hex: 0x3B8BFF)
        case .epic: return Color(hex: 0xA86CFF)
        case .mythic: return Color(hex: 0xF29CB1)
        case .legendary: return Color(hex: 0xF5C451)
        case .elite: return Color(hex: 0xFF5E3A)
        case .transcendent: return Color(hex: 0x9D6BFF)
        case .omniscient: return Color(hex: 0xFF4FD8)
        }
    }

    /// Matches the capitalisation used on the design label sheet.
    var label: String {
        self == .elite ? "Elite" : rawValue.uppercased()
    }
}

// MARK: - Move Blueprint

/// A combat move the player can equip. Blueprints carry a base animation
/// (so equipping one gives the player an attack animation immediately)
/// and are rolled from the gacha.
struct MoveBlueprint: Identifiable, Hashable {
    let id: String
    let name: String
    let rarity: Rarity
    let technique: CombatTechnique
    let blurb: String

    var baseAnimation: AnimationProject {
        PoseTemplate.animation(for: technique, name: name)
    }
}

enum BlueprintCatalog {
    static let all: [MoveBlueprint] = [
        // --- Base ---
        MoveBlueprint(id: "jab", name: "Jab", rarity: .base, technique: .punch,
                      blurb: "A quick straight punch. Nothing fancy, it works."),
        MoveBlueprint(id: "front_kick", name: "Front Kick", rarity: .base, technique: .kick,
                      blurb: "Lift, extend, connect."),
        MoveBlueprint(id: "hammer_drop", name: "Hammer Drop", rarity: .base, technique: .slam,
                      blurb: "Both fists up, then the ceiling comes down."),
        MoveBlueprint(id: "lunge_step", name: "Lunge Step", rarity: .base, technique: .dash,
                      blurb: "Close the gap before they notice you moved."),
        // --- Common ---
        MoveBlueprint(id: "cross", name: "Cross Strike", rarity: .common, technique: .punch,
                      blurb: "A committed straight with the rear arm."),
        MoveBlueprint(id: "sweep", name: "Low Sweep", rarity: .common, technique: .kick,
                      blurb: "Take the legs out from under them."),
        MoveBlueprint(id: "rising_knee", name: "Rising Knee", rarity: .common, technique: .kick,
                      blurb: "Drive upward, meet the chin halfway."),
        MoveBlueprint(id: "blink_rush", name: "Blink Rush", rarity: .common, technique: .dash,
                      blurb: "A short burst that eats the distance."),
        // --- Rare ---
        MoveBlueprint(id: "comet_hook", name: "Comet Hook", rarity: .rare, technique: .punch,
                      blurb: "A looping hook that lands like a falling star."),
        MoveBlueprint(id: "meteor_stomp", name: "Meteor Stomp", rarity: .rare, technique: .slam,
                      blurb: "Raise the sky, drop the ground."),
        MoveBlueprint(id: "smear_speedline", name: "SMEAR: Speedline", rarity: .rare, technique: .smear,
                      blurb: "One frame of motion, drawn in a single stroke."),
        MoveBlueprint(id: "copter_spin", name: "Copter Spin", rarity: .rare, technique: .spin,
                      blurb: "Arms out, world spinning, feet barely touching."),
        // --- Epic ---
        MoveBlueprint(id: "aftershock", name: "Aftershock Slam", rarity: .epic, technique: .slam,
                      blurb: "The impact arrives twice."),
        MoveBlueprint(id: "twin_fangs", name: "Twin Fang Barrage", rarity: .epic, technique: .punch,
                      blurb: "Two fists, one blur."),
        MoveBlueprint(id: "guillotine_kick", name: "Guillotine Kick", rarity: .epic, technique: .kick,
                      blurb: "A falling heel with a verdict attached."),
        MoveBlueprint(id: "phase_lance", name: "Phase Lance", rarity: .epic, technique: .dash,
                      blurb: "Become a line, arrive as a point."),
        // --- Mythic ---
        MoveBlueprint(id: "tornado", name: "Tornado Spin", rarity: .mythic, technique: .spin,
                      blurb: "A full rotation of pure momentum."),
        MoveBlueprint(id: "orbital_heel", name: "Orbital Heel", rarity: .mythic, technique: .kick,
                      blurb: "A kick that has left the atmosphere."),
        MoveBlueprint(id: "smear_comet_tail", name: "SMEAR: Comet Tail", rarity: .mythic, technique: .smear,
                      blurb: "The arc lingers long after the arm is gone."),
        // --- Legendary ---
        MoveBlueprint(id: "supernova", name: "Supernova Spin", rarity: .legendary, technique: .spin,
                      blurb: "Spin until the world blurs, then land."),
        MoveBlueprint(id: "warp", name: "Warp Breaker", rarity: .legendary, technique: .dash,
                      blurb: "Cross the arena in a single step."),
        MoveBlueprint(id: "asteroid_drop", name: "Asteroid Drop", rarity: .legendary, technique: .slam,
                      blurb: "Call it down from orbit, then mind the crater."),
        // --- Elite / Transcendent: reserved for future blueprints ---
        // --- Omniscient ---
        MoveBlueprint(id: "smear_ghost", name: "SMEAR: Ghost Fist", rarity: .omniscient, technique: .smear,
                      blurb: "The arm exists in two places at once."),
        MoveBlueprint(id: "smear_eclipse", name: "SMEAR: Eclipse Fang", rarity: .omniscient, technique: .smear,
                      blurb: "A strike drawn as a single unbroken arc."),
    ]

    static func blueprint(id: String) -> MoveBlueprint? {
        all.first { $0.id == id }
    }

    static func blueprints(in rarity: Rarity) -> [MoveBlueprint] {
        all.filter { $0.rarity == rarity }
    }
}

// MARK: - Gacha

enum Gacha {
    static let pullCost = 100
    static let duplicateRefund = 30
    /// Coin → pen exchange (battles pay coins; the gacha runs on pens).
    static let exchangeCoins = 100
    static let exchangePens = 20

    /// Tiers that actually contain blueprints. Elite and Transcendent are
    /// reserved for future moves, so they can't be rolled yet.
    static var activeRarities: [Rarity] {
        Rarity.allCases.filter { !BlueprintCatalog.blueprints(in: $0).isEmpty }
    }

    /// Total weight across rollable tiers (used for the displayed rates).
    static var totalActiveWeight: Double {
        activeRarities.reduce(0.0) { $0 + $1.weight }
    }

    static func rollRarity() -> Rarity {
        let total = totalActiveWeight
        var pick = Double.random(in: 0..<total)
        for rarity in activeRarities {
            pick -= rarity.weight
            if pick <= 0 { return rarity }
        }
        return activeRarities.first ?? .base
    }

    static func roll() -> MoveBlueprint {
        let rarity = rollRarity()
        let pool = BlueprintCatalog.blueprints(in: rarity)
        return pool.randomElement() ?? BlueprintCatalog.all[0]
    }
}

// MARK: - Pose templates (base animations for blueprints)

/// Procedurally built frame sequences, one per technique. These give every
/// blueprint a base animation so an equipped blueprint is immediately usable
/// in battle (and editable in the Studio).
enum PoseTemplate {
    static func angles(_ overrides: [(Bone, CGFloat)]) -> [Bone: CGFloat] {
        var a = Dictionary(uniqueKeysWithValues: Bone.allCases.map { ($0, $0.defaultAngle) })
        for (bone, value) in overrides { a[bone] = value }
        return a
    }

    static func pose(
        root: CGPoint = CGPoint(x: 200, y: 430),
        bodyRotation: CGFloat = 0,
        angles: [Bone: CGFloat]
    ) -> StickmanPose {
        StickmanPose(root: root, bodyRotation: bodyRotation, angles: angles)
    }

    static func animation(for technique: CombatTechnique, name: String) -> AnimationProject {
        AnimationProject(name: name, frames: frames(for: technique), fps: 12)
    }

    static func frames(for technique: CombatTechnique) -> [AnimationFrame] {
        switch technique {
        case .punch:
            return [
                AnimationFrame(pose: pose(angles: angles([
                    (.rightUpperArm, -0.9), (.rightForearm, -1.5),
                    (.leftUpperArm, 0.6), (.leftForearm, 1.2),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightUpperArm, -2.2), (.rightForearm, -2.7),
                    (.leftUpperArm, 0.6), (.leftForearm, 1.2),
                ]))),
                AnimationFrame(pose: pose(root: CGPoint(x: 215, y: 430), angles: angles([
                    (.rightUpperArm, -1.57), (.rightForearm, -1.57),
                    (.leftUpperArm, 0.9), (.leftForearm, 1.3),
                    (.torso, .pi + 0.12),
                ]))),
                AnimationFrame(pose: pose(root: CGPoint(x: 215, y: 430), angles: angles([
                    (.rightUpperArm, -1.57), (.rightForearm, -1.57),
                    (.leftUpperArm, 0.9), (.leftForearm, 1.3),
                    (.torso, .pi + 0.12),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightUpperArm, -0.9), (.rightForearm, -1.5),
                    (.leftUpperArm, 0.6), (.leftForearm, 1.2),
                ]))),
            ]

        case .kick:
            return [
                AnimationFrame(pose: pose(angles: angles([
                    (.leftUpperArm, 0.7), (.leftForearm, 1.1),
                    (.rightUpperArm, -0.7), (.rightForearm, -1.1),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightThigh, -1.3), (.rightShin, 2.2),
                    (.leftUpperArm, 0.8), (.rightUpperArm, -0.9),
                    (.torso, .pi - 0.08),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightThigh, -1.57), (.rightShin, 0),
                    (.leftUpperArm, 0.9), (.rightUpperArm, -1.0),
                    (.torso, .pi - 0.12),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightThigh, -1.57), (.rightShin, 0),
                    (.leftUpperArm, 0.9), (.rightUpperArm, -1.0),
                    (.torso, .pi - 0.12),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightThigh, -1.1), (.rightShin, 1.9),
                    (.leftUpperArm, 0.7), (.rightUpperArm, -0.8),
                ]))),
            ]

        case .slam:
            return [
                AnimationFrame(pose: pose(angles: angles([
                    (.leftUpperArm, .pi - 0.3), (.leftForearm, 0.25),
                    (.rightUpperArm, -.pi + 0.3), (.rightForearm, -0.25),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.leftUpperArm, .pi - 0.15), (.leftForearm, 0.15),
                    (.rightUpperArm, -.pi + 0.15), (.rightForearm, -0.15),
                ]))),
                AnimationFrame(pose: pose(root: CGPoint(x: 200, y: 455), angles: angles([
                    (.leftUpperArm, 0.3), (.leftForearm, 0.4),
                    (.rightUpperArm, -0.3), (.rightForearm, -0.4),
                    (.leftThigh, 0.3), (.leftShin, -0.45),
                    (.rightThigh, -0.3), (.rightShin, 0.45),
                ]))),
                AnimationFrame(pose: pose(root: CGPoint(x: 200, y: 455), angles: angles([
                    (.leftUpperArm, 0.3), (.leftForearm, 0.4),
                    (.rightUpperArm, -0.3), (.rightForearm, -0.4),
                    (.leftThigh, 0.3), (.leftShin, -0.45),
                    (.rightThigh, -0.3), (.rightShin, 0.45),
                ]))),
                AnimationFrame(pose: pose(angles: angles([
                    (.leftUpperArm, 0.5), (.rightUpperArm, -0.5),
                ]))),
            ]

        case .spin:
            var frames: [AnimationFrame] = []
            let steps = 7
            let totalSweep: CGFloat = 5.6
            for i in 0...steps {
                let br = CGFloat(i) * (totalSweep / CGFloat(steps))
                frames.append(AnimationFrame(pose: pose(
                    bodyRotation: br,
                    angles: angles([
                        (.leftUpperArm, .pi / 2), (.rightUpperArm, -.pi / 2),
                        (.leftForearm, 0.1), (.rightForearm, -0.1),
                        (.leftThigh, 0.3), (.rightThigh, -0.3),
                    ])
                )))
            }
            return frames

        case .dash:
            return [
                AnimationFrame(pose: pose(root: CGPoint(x: 150, y: 430), angles: angles([])),
                               hold: 1),
                AnimationFrame(pose: pose(root: CGPoint(x: 200, y: 425), angles: angles([
                    (.leftThigh, -0.8), (.leftShin, 0.5),
                    (.rightThigh, 0.7), (.rightShin, -0.35),
                    (.torso, .pi + 0.35),
                    (.leftUpperArm, -0.4), (.rightUpperArm, 0.4),
                ])), hold: 1),
                AnimationFrame(pose: pose(root: CGPoint(x: 270, y: 425), angles: angles([
                    (.leftThigh, -1.0), (.leftShin, 0.6),
                    (.rightThigh, 0.8), (.rightShin, -0.4),
                    (.torso, .pi + 0.4),
                    (.leftUpperArm, -0.5), (.rightUpperArm, 0.5),
                ])), hold: 1),
                AnimationFrame(pose: pose(root: CGPoint(x: 330, y: 430), angles: angles([
                    (.leftThigh, -0.6), (.leftShin, 0.3),
                    (.rightThigh, 0.9), (.rightShin, -0.5),
                    (.torso, .pi + 0.3),
                ])), hold: 1),
                AnimationFrame(pose: pose(root: CGPoint(x: 350, y: 430), angles: angles([]))),
            ]

        case .smear:
            return [
                AnimationFrame(pose: pose(angles: angles([
                    (.rightUpperArm, -0.9), (.rightForearm, -1.5),
                    (.leftUpperArm, 0.6), (.leftForearm, 1.2),
                ])), hold: 1),
                // Extreme windup: arm whipped back over the shoulder.
                AnimationFrame(pose: pose(angles: angles([
                    (.rightUpperArm, -2.9), (.rightForearm, -2.9),
                    (.leftUpperArm, 0.7), (.leftForearm, 1.3),
                    (.torso, .pi - 0.2),
                ])), hold: 1),
                // The smear frame: the arm snaps through ~1.4 rad in one tick.
                AnimationFrame(pose: pose(root: CGPoint(x: 230, y: 430), angles: angles([
                    (.rightUpperArm, -1.57), (.rightForearm, -1.57),
                    (.leftUpperArm, 1.0), (.leftForearm, 1.4),
                    (.torso, .pi + 0.2),
                ])), hold: 1),
                AnimationFrame(pose: pose(root: CGPoint(x: 230, y: 430), angles: angles([
                    (.rightUpperArm, -1.57), (.rightForearm, -1.57),
                    (.leftUpperArm, 1.0), (.leftForearm, 1.4),
                    (.torso, .pi + 0.2),
                ])), hold: 1),
                AnimationFrame(pose: pose(angles: angles([
                    (.rightUpperArm, -0.9), (.rightForearm, -1.5),
                ]))),
            ]
        }
    }
}
