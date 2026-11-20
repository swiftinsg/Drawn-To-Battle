import SwiftUI

// MARK: - Accessories

/// How an accessory is painted onto the home fighter.
enum AccessoryRender: String, Codable {
    case crown
    case wings
    case halo
    case star
    case butterflies
    case leaves
    case orbit
}

/// Gear available from world gachas and level milestones.
enum Accessory: String, Codable, CaseIterable, Identifiable {
    // Earth gacha: nature, growth and glowing creatures.
    case glowButterflies
    case driftingLeaves
    case pebbleOrbit
    case leafCrown
    case vineWreath
    case mossCrest
    // Uranus gacha: ice and water.
    case iceWings
    case frostRing
    case tideOrbit
    case crystalHalo
    // Sun gacha: angelic light and fire.
    case solarHalo
    case flameCrown
    case angelWings
    case emberCrown
    case flareWings
    // Level milestones
    case championCrown
    case meteorWings
    case galacticHalo
    case legendStar

    var id: String { rawValue }

    var name: String {
        switch self {
        case .glowButterflies: return "Glow Butterflies"
        case .driftingLeaves: return "Drifting Leaves"
        case .pebbleOrbit: return "Pebble Orbit"
        case .leafCrown: return "Leaf Crown"
        case .vineWreath: return "Vine Wreath"
        case .mossCrest: return "Moss Crest"
        case .iceWings: return "Ice Wings"
        case .frostRing: return "Frost Ring"
        case .tideOrbit: return "Tide Orbit"
        case .crystalHalo: return "Crystal Halo"
        case .solarHalo: return "Solar Halo"
        case .flameCrown: return "Flame Crown"
        case .angelWings: return "Angel Wings"
        case .emberCrown: return "Ember Crown"
        case .flareWings: return "Flare Wings"
        case .championCrown: return "Champion Crown"
        case .meteorWings: return "Meteor Wings"
        case .galacticHalo: return "Galactic Halo"
        case .legendStar: return "Legend Star"
        }
    }

    /// Boss whose world gacha contains this accessory.
    var bossID: String? {
        switch self {
        case .glowButterflies, .driftingLeaves, .pebbleOrbit,
             .leafCrown, .vineWreath, .mossCrest: return "earth"
        case .iceWings, .frostRing, .tideOrbit, .crystalHalo: return "mars"   // Uranus (save id)
        case .solarHalo, .flameCrown, .angelWings, .emberCrown, .flareWings: return "sun"
        case .championCrown, .meteorWings, .galacticHalo, .legendStar: return nil
        }
    }

    var planetName: String? {
        switch bossID {
        case "earth": return "EARTH"
        case "mars": return "URANUS"
        case "sun": return "SUN"
        default: return nil
        }
    }

    /// Level that awards this accessory outright.
    var milestoneLevel: Int? {
        switch self {
        case .championCrown: return 5
        case .meteorWings: return 10
        case .galacticHalo: return 15
        case .legendStar: return 20
        default: return nil
        }
    }

    static let milestoneLevels = [5, 10, 15, 20]

    static func accessory(forMilestone level: Int) -> Accessory? {
        allCases.first { $0.milestoneLevel == level }
    }

    /// The accessory granted free when a world is first conquered.
    static func signature(forBoss id: String) -> Accessory? {
        switch id {
        case "earth": return .glowButterflies
        case "mars": return .iceWings
        case "sun": return .solarHalo
        default: return nil
        }
    }

    /// Full pool for a world gacha. Signature piece can still be drawn again.
    static func pool(forBoss id: String) -> [Accessory] {
        allCases.filter { $0.bossID == id }
    }

    /// Old accessory ids mapped to their new themed equivalents so existing
    /// TestFlight saves keep what they earned.
    static func migratedID(_ id: String) -> String {
        switch id {
        case "leafCrown": return "glowButterflies"
        case "vineWreath": return "driftingLeaves"
        case "mossCrest": return "pebbleOrbit"
        case "crystalHalo": return "tideOrbit"
        case "emberCrown": return "flameCrown"
        case "flareWings": return "angelWings"
        default: return id
        }
    }

    var render: AccessoryRender {
        switch self {
        case .leafCrown, .vineWreath, .mossCrest, .flameCrown,
             .emberCrown, .championCrown:
            return .crown
        case .iceWings, .angelWings, .flareWings, .meteorWings:
            return .wings
        case .frostRing, .crystalHalo, .solarHalo, .galacticHalo:
            return .halo
        case .legendStar:
            return .star
        case .glowButterflies:
            return .butterflies
        case .driftingLeaves:
            return .leaves
        case .pebbleOrbit, .tideOrbit:
            return .orbit
        }
    }

    /// Tint used for the accessory itself and for collection chips.
    var tintHex: UInt32 {
        switch self {
        case .glowButterflies: return 0xA8F06A
        case .driftingLeaves: return 0x4ED36E
        case .pebbleOrbit: return 0xC49A6C
        case .leafCrown: return 0x4ED36E
        case .vineWreath: return 0x2E8B57
        case .mossCrest: return 0x9ACD32
        case .iceWings: return 0x4FC3F7
        case .frostRing: return 0x81D4FA
        case .tideOrbit: return 0x29B6F6
        case .crystalHalo: return 0xB3E5FC
        case .solarHalo: return 0xF5C451
        case .flameCrown: return 0xFF8A3C
        case .angelWings: return 0xFFE8A8
        case .emberCrown: return 0xFF8A3C
        case .flareWings: return 0xFF6B4A
        case .championCrown: return 0xFFD54F
        case .meteorWings: return 0xE86A6A
        case .galacticHalo: return 0xA86CFF
        case .legendStar: return 0xFFD700
        }
    }

    var tint: Color { Color(hex: tintHex) }

    var subtitle: String {
        if let planet = planetName {
            return "Dropped by the \(planet) accessory gacha."
        }
        return "Reached at level \(milestoneLevel ?? 0)."
    }
}

// MARK: - Daily streak

struct DailyReward {
    let coins: Int
    let pens: Int
    let xp: Int
}

// MARK: - Level road

/// One stop on the Level Road, reached at the given XP threshold.
/// Reaching a level grants its rewards automatically (see
/// `GameSave.claimReachedLevelRoadSteps`).
struct LevelRoadStep {
    let level: Int
    let rewardCoins: Int
    let rewardStardust: Int

    /// XP needed to reach this level (reusing the leveling curve).
    var xpNeeded: Int { GameSave.cumulativeXP(for: level) }

    /// Whether the player has reached this level's threshold.
    func isReached(by experience: Int) -> Bool {
        experience >= xpNeeded
    }
}
