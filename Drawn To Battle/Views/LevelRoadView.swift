import SwiftUI

// MARK: - Level Road
//
// A progression track on the solar system: stops at each level's XP
// threshold. Reaching a level's threshold grants its rewards automatically
// (see `GameSave.claimReachedLevelRoadSteps`).

struct LevelRoadView: View {
    @ObservedObject var game: GameSave

    private var steps = GameSave.levelRoadSteps

    /// The next level reward ahead of the player's current level.
    private var nextStep: LevelRoadStep? {
        steps.first { !$0.isReached(by: game.experience) }
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("LEVEL ROAD")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                )

            ForEach(steps, id: \.level) { step in
                LevelRoadStop(step: step, isReached: step.isReached(by: game.experience))
            }

            Spacer()

            if let next = nextStep {
                Text(rewardText(next))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func rewardText(_ step: LevelRoadStep) -> String {
        let bonus = step.rewardCosmetic.map { " + \($0.name)" } ?? ""
        return "NEXT L\(step.level) +\(step.rewardCoins) coins +\(step.rewardStardust) pens\(bonus)"
    }
}

/// One stop on the road: a circle with the level number; reached stops are
/// gold, the rest are dim.
private struct LevelRoadStop: View {
    let step: LevelRoadStep
    let isReached: Bool

    var body: some View {
        Circle()
            .fill(isReached ? Color(hex: 0xF5C451) : Color.white.opacity(0.06))
            .stroke(isReached ? Color(hex: 0xF5C451) : Color.white.opacity(0.10), lineWidth: 2)
            .frame(width: 28, height: 28)
            .overlay(
                Text("L\(step.level)")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(isReached ? .black : Color.white.opacity(0.6))
            )
    }
}
