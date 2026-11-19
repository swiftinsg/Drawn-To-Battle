import SwiftUI
import UIKit
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
            title: "The Sleeping Mountain", hp: 140,
            requiredTechnique: .smear,
            rewardFirstClear: 120, rewardRepeat: 40,
            bodyColor: 0x3FA65C, accentColor: 0x4C8DFF,
            attacks: [
                BossAttackDef(name: "BOULDER TOSS", kind: .projectileLob, damage: 16, telegraph: 0.9),
                BossAttackDef(name: "QUAKE WAVE", kind: .groundShock, damage: 18, telegraph: 0.9),
            ],
            unlockAfter: nil
        ),
        BossDefinition(
            // Internal id stays "mars" so existing save records keep working.
            id: "mars", planetName: "URANUS", bossName: "AZURE WARLOCK",
            title: "The Ice Duelist", hp: 210,
            requiredTechnique: .kick,
            rewardFirstClear: 180, rewardRepeat: 55,
            bodyColor: 0x4FC3F7, accentColor: 0xB3E5FC,
            attacks: [
                BossAttackDef(name: "FROST RAM", kind: .charge, damage: 22, telegraph: 0.8),
                BossAttackDef(name: "ICE UPPERCUT", kind: .melee, damage: 19, telegraph: 0.7),
                BossAttackDef(name: "SHARD BURST", kind: .fan, damage: 16, telegraph: 0.85),
            ],
            unlockAfter: "earth"
        ),
        BossDefinition(
            id: "sun", planetName: "SUN", bossName: "SOLAR OVERLORD",
            title: "The Burning Eye", hp: 380,
            requiredTechnique: .spin,
            rewardFirstClear: 340, rewardRepeat: 95,
            bodyColor: 0xF5C451, accentColor: 0xFF8A3C,
            attacks: [
                BossAttackDef(name: "SOLAR FLARE", kind: .flare, damage: 28, telegraph: 0.85),
                BossAttackDef(name: "CORONA RING", kind: .fan, damage: 22, telegraph: 0.6),
                BossAttackDef(name: "HEAT LUNGE", kind: .charge, damage: 30, telegraph: 0.5),
                BossAttackDef(name: "SUNSPOT SLAM", kind: .groundShock, damage: 26, telegraph: 0.72),
            ],
            unlockAfter: "mars"
        ),
    ]

    static func boss(id: String) -> BossDefinition? {
        all.first { $0.id == id }
    }

    // MARK: Victory payouts

    /// Coins paid for beating this boss (full first-clear / repeat reward).
    func coinReward(firstClear: Bool) -> Int {
        firstClear ? rewardFirstClear : rewardRepeat
    }

    /// Pens paid alongside the coins: half of the coin reward, rounded up.
    func penReward(firstClear: Bool) -> Int {
        Int(ceil(Double(coinReward(firstClear: firstClear)) / 2))
    }

    /// XP follows the same first-clear/repeat split as coins.
    func xpReward(firstClear: Bool) -> Int {
        coinReward(firstClear: firstClear)
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

/// One entry in the gacha history (newest first, capped at 20).
struct GachaPullRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let blueprintID: String
    let isNew: Bool
    let date: Date
}

// MARK: - Persistent game save

final class GameSave: ObservableObject {
    /// Pens granted to a fresh fighter (and after resetting progress).
    static let startingStardust = 100
    /// Foundational moves every fighter owns from the start.
    static let starterBlueprintIDs: Set<String> = [
        "jab", "front_kick", "hammer_drop", "lunge_step"
    ]

    @Published var stardust: Int = GameSave.startingStardust {
        didSet { persist() }
    }
    /// Total XP earned. Level is derived from this so it can't drift out of sync.
    @Published var experience: Int = 0 {
        didSet { persist() }
    }
    @Published var ownedBlueprints: Set<String> = GameSave.starterBlueprintIDs {
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
    /// Coins — earned from battles. (Pens/stardust above is the gacha currency.)
    @Published var coins: Int = 100{
        didSet { persist() }
    }
    /// The fighter's name, chosen on first launch.
    @Published var username: String = "" {
        didSet { persist() }
    }
    /// Profile photo chosen from the system photo library (compressed JPEG).
    @Published var profileImageData: Data? {
        didSet { persist() }
    }
    /// Last 20 gacha pulls, newest first.
    @Published var gachaHistory: [GachaPullRecord] = [] {
        didSet { persist() }
    }
    /// World gear currently shown on the home-screen fighter.
    @Published var equippedAccessory: Accessory? {
        didSet { persist() }
    }
    /// Consecutive days the daily reward has been claimed.
    @Published var dailyStreak: Int = 0 {
        didSet { persist() }
    }
    /// Local calendar day (yyyy-MM-dd) of the last daily claim.
    @Published var lastDailyClaimDate: String? {
        didSet { persist() }
    }
    var hasUsername: Bool { !username.isEmpty }

    private static let key = "DrawnToBattle.save.v1"

    /// Coins charged by the settings screen for changing the fighter's name.
    static let nameChangeCost = 1000
    static let minNameLength = 3
    static let maxNameLength = 14

    /// XP awarded for finding a new move or rerolling an owned one.
    private static let xpPerNewBlueprint = 25
    private static let xpPerDuplicate = 10

    /// Small rewards for logging in each day. Longer streaks pay a bit more.
    static let dailyRewards: [DailyReward] = [
        DailyReward(coins: 40, pens: 10, xp: 10),
        DailyReward(coins: 60, pens: 10, xp: 15),
        DailyReward(coins: 80, pens: 20, xp: 20),
        DailyReward(coins: 100, pens: 20, xp: 25),
        DailyReward(coins: 120, pens: 30, xp: 30),
        DailyReward(coins: 150, pens: 30, xp: 40),
        DailyReward(coins: 300, pens: 60, xp: 60),
    ]

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        return formatter
    }()

    static func dayKey(for date: Date = Date()) -> String {
        dayFormatter.string(from: date)
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(SaveData.self, from: data) {
            stardust = saved.stardust
            experience = saved.experience ?? 0
            // Older saves may not have the starter set. Grant it without
            // taking away anything the player already pulled.
            let needsStarterMoves = !Self.starterBlueprintIDs.isSubset(of: saved.ownedBlueprints)
            ownedBlueprints = saved.ownedBlueprints.union(Self.starterBlueprintIDs)
            equipped = saved.equipped
            defeatedBosses = saved.defeatedBosses
            blueprintEdits = saved.blueprintEdits ?? [:]
            coins = saved.coins ?? 0
            username = saved.username ?? ""
            profileImageData = saved.profileImageData
            gachaHistory = saved.gachaHistory ?? []
            equippedAccessory = saved.equippedAccessory.flatMap { Accessory(rawValue: $0) }
            dailyStreak = saved.dailyStreak ?? 0
            lastDailyClaimDate = saved.lastDailyClaimDate
            if needsStarterMoves { persist() }
        }
    }

    // MARK: Leveling

    var level: Int { Self.level(for: experience) }

    /// XP needed to enter a given level, measured from level 1.
    static func cumulativeXP(for level: Int) -> Int {
        let steps = max(0, level - 1)
        return 25 * steps * (steps + 3)
    }

    static func level(for totalXP: Int) -> Int {
        var current = 1
        while cumulativeXP(for: current + 1) <= totalXP { current += 1 }
        return current
    }

    /// XP progress inside the current level.
    var levelProgress: (current: Int, needed: Int) {
        let base = Self.cumulativeXP(for: level)
        let next = Self.cumulativeXP(for: level + 1)
        return (experience - base, next - base)
    }

    func addExperience(_ amount: Int) {
        experience += max(0, amount)
    }

    // MARK: Costumes

    func isAccessoryUnlocked(_ accessory: Accessory) -> Bool {
        defeatedBosses.contains(accessory.bossID)
    }

    var unlockedAccessories: [Accessory] {
        Accessory.allCases.filter { isAccessoryUnlocked($0) }
    }

    func equip(accessory: Accessory) {
        guard isAccessoryUnlocked(accessory) else { return }
        equippedAccessory = accessory
    }

    func clearAccessory() {
        equippedAccessory = nil
    }

    // MARK: Daily streak

    var claimedDailyToday: Bool { lastDailyClaimDate == Self.dayKey() }

    /// Reward for the next claim. The table repeats after a full week.
    var nextDailyReward: DailyReward {
        guard !Self.dailyRewards.isEmpty else {
            return DailyReward(coins: 0, pens: 0, xp: 0)
        }
        return Self.dailyRewards[dailyStreak % Self.dailyRewards.count]
    }

    /// Position in the current 7-day reward cycle (0 = day one).
    var dailyCycleDay: Int { dailyStreak % max(1, Self.dailyRewards.count) }

    @discardableResult
    func claimDaily() -> DailyReward? {
        guard !claimedDailyToday else { return nil }

        let reward = nextDailyReward
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        if lastDailyClaimDate == Self.dayKey(for: yesterday) {
            dailyStreak += 1
        } else {
            dailyStreak = 1
        }
        lastDailyClaimDate = Self.dayKey()

        coins += reward.coins
        stardust += reward.pens
        addExperience(reward.xp)
        return reward
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

    /// Spends coins to rename the fighter. Fails without spending if the name
    /// is blank, unchanged, too long, or unaffordable.
    @discardableResult
    func changeUsername(to rawName: String) -> Bool {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minNameLength,
              trimmed.count <= Self.maxNameLength,
              trimmed != username, coins >= Self.nameChangeCost else { return false }
        coins -= Self.nameChangeCost
        username = trimmed
        return true
    }

    /// Downscales and compresses a picked photo so the save stays small.
    func setProfileImage(_ image: UIImage) {
        let maxSide: CGFloat = 512
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        profileImageData = rendered.jpegData(compressionQuality: 0.75)
    }

    func clearProfileImage() {
        profileImageData = nil
    }

    @discardableResult
    func registerPull(_ blueprint: MoveBlueprint) -> Bool /* isNew */ {
        if ownedBlueprints.contains(blueprint.id) {
            // Collection's complete — extra pulls now pay coins and XP.
            coins += Gacha.duplicateRefund
            addExperience(Self.xpPerDuplicate)
            return false
        }
        ownedBlueprints.insert(blueprint.id)
        addExperience(Self.xpPerNewBlueprint)
        return true
    }

    /// Keeps the last 20 pulls for the history screen.
    func recordPull(_ blueprint: MoveBlueprint, isNew: Bool) {
        let record = GachaPullRecord(
            id: UUID(),
            blueprintID: blueprint.id,
            isNew: isNew,
            date: Date()
        )
        gachaHistory.insert(record, at: 0)
        if gachaHistory.count > 20 { gachaHistory.removeLast() }
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
        coins += boss.coinReward(firstClear: first)
        stardust += boss.penReward(firstClear: first)
        addExperience(boss.xpReward(firstClear: first))
        if first { defeatedBosses.insert(boss.id + "_rewarded") }
    }

    /// Wipes progress back to a fresh save, keeping the fighter's identity.
    func resetProgress() {
        stardust = Self.startingStardust
        experience = 0
        ownedBlueprints = Self.starterBlueprintIDs
        equipped = nil
        defeatedBosses = []
        blueprintEdits = [:]
        coins = 100
        gachaHistory = []
        equippedAccessory = nil
        dailyStreak = 0
        lastDailyClaimDate = nil
    }

    func isUnlocked(_ boss: BossDefinition) -> Bool {
        guard let prereq = boss.unlockAfter else { return true }
        return defeatedBosses.contains(prereq)
    }

    // MARK: Persistence

    private struct SaveData: Codable {
        var stardust: Int
        var experience: Int?
        var ownedBlueprints: Set<String>
        var equipped: EquippedLoadout?
        var defeatedBosses: Set<String>
        var blueprintEdits: [String: AnimationProject]?
        var coins: Int?
        var username: String?
        var profileImageData: Data?
        var gachaHistory: [GachaPullRecord]?
        var equippedAccessory: String?
        var dailyStreak: Int?
        var lastDailyClaimDate: String?
    }

    private func persist() {
        let data = SaveData(
            stardust: stardust,
            experience: experience,
            ownedBlueprints: ownedBlueprints,
            equipped: equipped,
            defeatedBosses: defeatedBosses,
            blueprintEdits: blueprintEdits,
            coins: coins,
            username: username,
            profileImageData: profileImageData,
            gachaHistory: gachaHistory,
            equippedAccessory: equippedAccessory?.rawValue,
            dailyStreak: dailyStreak,
            lastDailyClaimDate: lastDailyClaimDate
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }
}
