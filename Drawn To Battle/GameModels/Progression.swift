import SwiftUI

// MARK: - Costumes

/// Gear unlocked by conquering each world. Equipped accessories are drawn on
/// the fighter that sits in the middle of the home screen.
enum Accessory: String, Codable, CaseIterable, Identifiable {
    case leafCrown
    case iceWings
    case solarHalo

    var id: String { rawValue }

    var name: String {
        switch self {
        case .leafCrown: return "Leaf Crown"
        case .iceWings: return "Ice Wings"
        case .solarHalo: return "Solar Halo"
        }
    }

    /// Boss whose world drops this costume.
    var bossID: String {
        switch self {
        case .leafCrown: return "earth"
        case .iceWings: return "mars"   // internal id for Uranus
        case .solarHalo: return "sun"
        }
    }

    var planetName: String {
        switch self {
        case .leafCrown: return "EARTH"
        case .iceWings: return "URANUS"
        case .solarHalo: return "SUN"
        }
    }

    var subtitle: String {
        switch self {
        case .leafCrown: return "Woven from the forests of Earth."
        case .iceWings: return "Frosted wings of the Azure Warlock."
        case .solarHalo: return "A ring of pure sunlight."
        }
    }

    var tint: Color {
        switch self {
        case .leafCrown: return Color(hex: 0x4ED36E)
        case .iceWings: return Color(hex: 0x4FC3F7)
        case .solarHalo: return Color(hex: 0xF5C451)
        }
    }
}

// MARK: - Daily streak

struct DailyReward {
    let coins: Int
    let pens: Int
    let xp: Int
}

// MARK: - Level road

/// One stop on the Level Road — reached at the given XP threshold.
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
