import SwiftUI

// MARK: - Level Road
//
// A progression track with one stop every five levels. Reaching a stop unlocks
// its reward, but the player claims it by hand. The compact bar stays on the
// solar system; the full page is opened from the home hub.

struct LevelRoadView: View {
    @ObservedObject var game: GameSave

    private var steps = GameSave.levelRoadSteps

    /// The next stop ahead of the player's current level.
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
                LevelRoadStop(
                    step: step,
                    isReached: step.isReached(by: game.experience),
                    isClaimed: game.claimedLevelSteps.contains(step.level)
                )
            }

            Spacer()

            if let pending = game.pendingLevelRoadSteps.first {
                Text("CLAIM L\(pending.level)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF5C451))
            } else if let next = nextStep {
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

/// One stop on the road: reached stops are gold, claimed stops get a check,
/// and an unclaimed stop gets a question mark.
private struct LevelRoadStop: View {
    let step: LevelRoadStep
    let isReached: Bool
    let isClaimed: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isReached ? Color(hex: 0xF5C451) : Color.white.opacity(0.06))
                .stroke(isReached ? Color(hex: 0xF5C451) : Color.white.opacity(0.10), lineWidth: 2)
                .frame(width: 28, height: 28)

            if isClaimed {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.black)
            } else {
                Text("L\(step.level)")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(isReached ? .black : Color.white.opacity(0.6))
            }

            if isReached && !isClaimed {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF5C451))
                    .offset(x: 12, y: -12)
            }
        }
    }
}

// MARK: - Full level road page

struct LevelRoadPageView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    private var steps = GameSave.levelRoadSteps

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LEVEL ROAD")
                            .font(DrawnToBattleTypography.display(26))
                            .foregroundStyle(.white)
                        Text("LEVEL \(game.level)  •  CLAIM EACH STOP BY HAND")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close level road")
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                if game.hasPendingLevelRoadRewards {
                    Text("REWARDS READY TO CLAIM")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451))
                        .padding(.bottom, 6)
                }

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(steps, id: \.level) { step in
                            LevelRoadCard(
                                step: step,
                                game: game,
                                isReached: step.isReached(by: game.experience),
                                isClaimed: game.claimedLevelSteps.contains(step.level)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
    }
}

private struct LevelRoadCard: View {
    let step: LevelRoadStep
    @ObservedObject var game: GameSave
    let isReached: Bool
    let isClaimed: Bool

    private var claimable: Bool { isReached && !isClaimed }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(claimable ? Color(hex: 0xF5C451)
                          : isClaimed ? Color(hex: 0x4ED36E).opacity(0.7)
                          : Color.white.opacity(0.08))
                    .frame(width: 46, height: 46)

                if claimable {
                    Image(systemName: "questionmark")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.black)
                } else if isClaimed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.black)
                } else {
                    Text("L\(step.level)")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("LEVEL \(step.level)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    Text("+\(step.rewardCoins) COINS")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
                    Text("+\(step.rewardStardust) PENS")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0xA8F06A).opacity(0.85))
                }

                if let cosmetic = step.rewardCosmetic {
                    HStack(spacing: 4) {
                        FighterFigureView(accessory: cosmetic)
                            .frame(width: 22, height: 28)
                        Text(cosmetic.name.uppercased())
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(cosmetic.tint)
                    }
                }
            }

            Spacer()

            if claimable {
                Button {
                    game.claimLevelRoadStep(step.level)
                    Haptics.success()
                } label: {
                    Text("CLAIM")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(hex: 0xF5C451)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Claim level \(step.level) reward")
            } else if isClaimed {
                Text("CLAIMED")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x4ED36E).opacity(0.8))
            } else {
                Text("REACH L\(step.level)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: claimable ? 0x1B1A16 : 0x14161E))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(claimable
                                ? Color(hex: 0xF5C451).opacity(0.7)
                                : Color.white.opacity(0.08),
                                lineWidth: claimable ? 2 : 1)
                )
        )
    }
}
