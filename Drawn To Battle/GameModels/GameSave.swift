import SwiftUI
import Combine

// MARK: - Boss definitions

enum BossAttackKind: String, Codable {
    case projectileLob   // lobbed boulder — dodge
    case groundShock     // wave along the floor — jump
    case charge          // boss rushes across — dodge/jump
    case flare           // full-screen wave — block
    case fan             // spread of projectiles — dodge gaps
    case melee           // close-range strike — move away

    var hint: String {
        switch self {
        case .projectileLob: return "DODGE!"
        case .groundShock: return "JUMP!"
        case .charge: return "MOVE!"
        case .flare: return "BLOCK!"
        case .fan: return "DODGE!"
        case .melee: return "BACK OFF!"
        }
    }
}

struct BossAttackDef: Hashable {
    let name: String
    let kind: BossAttackKind
    let damage: Double
    let telegraph: Double
}

struct BossDefinition: Identifiable, Hashable {
    let id: String
    let planetName: String
    let bossName: String
    let title: String
    let hp: Double
    /// The boss only takes real damage from animations using this technique.
    let requiredTechnique: CombatTechnique
    let rewardFirstClear: Int
    let rewardRepeat: Int
    let bodyColor: UInt32
    let accentColor: UInt32
    let attacks: [BossAttackDef]
    /// Boss id that must be defeated first (nil = available from the start).
    let unlockAfter: String?

    static let all: [BossDefinition] = [
        BossDefinition(
            id: "earth", planetName: "EARTH", bossName: "TERRA COLOSSUS",
            title: "The Sleeping Mountain", hp: 90,
            requiredTechnique: .smear,
            rewardFirstClear: 120, rewardRepeat: 40,
            bodyColor: 0x3FA65C, accentColor: 0x4C8DFF,
            attacks: [
                BossAttackDef(name: "BOULDER TOSS", kind: .projectileLob, damage: 12, telegraph: 1.0),
                BossAttackDef(name: "QUAKE WAVE", kind: .groundShock, damage: 14, telegraph: 1.1),
            ],
            unlockAfter: nil
        ),
        BossDefinition(
            id: "mars", planetName: "MARS", bossName: "CRIMSON WARLOCK",
            title: "The Red Duelist", hp: 130,
            requiredTechnique: .kick,
            rewardFirstClear: 180, rewardRepeat: 55,
            bodyColor: 0xE86A3A, accentColor: 0xFFB37A,
            attacks: [
                BossAttackDef(name: "WAR RAM", kind: .charge, damage: 18, telegraph: 0.9),
                BossAttackDef(name: "EMBER UPPERCUT", kind: .melee, damage: 15, telegraph: 0.8),
                BossAttackDef(name: "SPEAR SHARDS", kind: .fan, damage: 12, telegraph: 1.0),
            ],
            unlockAfter: "earth"
        ),
        BossDefinition(
            id: "sun", planetName: "SUN", bossName: "SOLAR OVERLORD",
            title: "The Burning Eye", hp: 170,
            requiredTechnique: .spin,
            rewardFirstClear: 260, rewardRepeat: 70,
            bodyColor: 0xF5C451, accentColor: 0xFF8A3C,
            attacks: [
                BossAttackDef(name: "SOLAR FLARE", kind: .flare, damage: 16, telegraph: 1.2),
                BossAttackDef(name: "CORONA RING", kind: .fan, damage: 12, telegraph: 0.9),
                BossAttackDef(name: "HEAT LUNGE", kind: .charge, damage: 18, telegraph: 0.8),
            ],
            unlockAfter: "mars"
        ),
    ]

    static func boss(id: String) -> BossDefinition? {
        all.first { $0.id == id }
    }
}

// MARK: - Loadout

enum LoadoutSource: Codable, Equatable {
    case blueprint(String)   // blueprint id
    case studio(String)      // saved project name
}

/// What the player takes into battle: the animation itself plus where it came from.
struct EquippedLoadout: Codable, Equatable {
    var source: LoadoutSource
    var project: AnimationProject
}

// MARK: - Persistent game save

final class GameSave: ObservableObject {
    @Published var stardust: Int = 150 {
        didSet { persist() }
    }
    @Published var ownedBlueprints: Set<String> = [] {
        didSet { persist() }
    }
    @Published var equipped: EquippedLoadout? {
        didSet { persist() }
    }
    @Published var defeatedBosses: Set<String> = [] {
        didSet { persist() }
    }
    /// Player-customized versions of blueprints, keyed by blueprint id.
    @Published var blueprintEdits: [String: AnimationProject] = [:] {
        didSet { persist() }
    }

    private static let key = "DrawnToBattle.save.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(SaveData.self, from: data) {
            stardust = saved.stardust
            ownedBlueprints = saved.ownedBlueprints
            equipped = saved.equipped
            defeatedBosses = saved.defeatedBosses
            blueprintEdits = saved.blueprintEdits ?? [:]
        }
    }

    // MARK: Mutations

    func spendStardust(_ amount: Int) -> Bool {
        guard stardust >= amount else { return false }
        stardust -= amount
        return true
    }

    func addStardust(_ amount: Int) {
        stardust += amount
    }

    @discardableResult
    func registerPull(_ blueprint: MoveBlueprint) -> Bool /* isNew */ {
        if ownedBlueprints.contains(blueprint.id) {
            stardust += Gacha.duplicateRefund
            return false
        }
        ownedBlueprints.insert(blueprint.id)
        return true
    }

    func equip(blueprint: MoveBlueprint) {
        // Use the player's customized version if they've edited this blueprint.
        let project = blueprintEdits[blueprint.id] ?? blueprint.baseAnimation
        equipped = EquippedLoadout(source: .blueprint(blueprint.id), project: project)
    }

    func equip(project: AnimationProject) {
        equipped = EquippedLoadout(source: .studio(project.name), project: project)
    }

    /// The player's saved customization of a blueprint, if any.
    func blueprintEdit(id: String) -> AnimationProject? {
        blueprintEdits[id]
    }

    /// Stores a customized version of a blueprint. If that blueprint is
    /// currently equipped, the loadout updates immediately.
    func setBlueprintEdit(_ id: String, project: AnimationProject) {
        blueprintEdits[id] = project
        if case .blueprint(let equippedID) = equipped?.source, equippedID == id {
            equipped?.project = project
        }
    }

    /// Removes a customization, restoring the blueprint's original animation.
    func clearBlueprintEdit(_ id: String) {
        blueprintEdits[id] = nil
        if case .blueprint(let equippedID) = equipped?.source, equippedID == id,
           let base = BlueprintCatalog.blueprint(id: id)?.baseAnimation {
            equipped?.project = base
        }
    }

    func registerVictory(boss: BossDefinition) {
        defeatedBosses.insert(boss.id)
        let first = !defeatedBosses.contains(boss.id + "_rewarded")
        stardust += first ? boss.rewardFirstClear : boss.rewardRepeat
        if first { defeatedBosses.insert(boss.id + "_rewarded") }
    }

    func isUnlocked(_ boss: BossDefinition) -> Bool {
        guard let prereq = boss.unlockAfter else { return true }
        return defeatedBosses.contains(prereq)
    }

    // MARK: Persistence

    private struct SaveData: Codable {
        var stardust: Int
        var ownedBlueprints: Set<String>
        var equipped: EquippedLoadout?
        var defeatedBosses: Set<String>
        var blueprintEdits: [String: AnimationProject]?
    }

    private func persist() {
        let data = SaveData(
            stardust: stardust,
            ownedBlueprints: ownedBlueprints,
            equipped: equipped,
            defeatedBosses: defeatedBosses,
            blueprintEdits: blueprintEdits
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }
}
