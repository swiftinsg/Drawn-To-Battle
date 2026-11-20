import SwiftUI

// MARK: - Daily streak

/// A small daily login reward. Consecutive days build the streak; a missed day
/// restarts it at one. The seven rewards repeat each week.
struct DailyRewardView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    @State private var claimedReward: DailyReward?

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: 0xF5C451).opacity(0.1))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 70)
                    .offset(y: -geo.size.height * 0.35)
            }
            .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    weekStrip
                    rewardCard

                    if let claimedReward {
                        Text("CLAIMED!  +\(claimedReward.coins) COINS  •  +\(claimedReward.pens) PENS  •  +\(claimedReward.xp) XP")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451))
                            .multilineTextAlignment(.center)
                            .transition(.scale.combined(with: .opacity))
                    }

                    claimButton

                    Text("Come back tomorrow for the next reward. Missing a day restarts the streak.")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(22)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .top) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color(hex: 0xFF8A3C))
                .shadow(color: Color(hex: 0xFF8A3C).opacity(0.5), radius: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text("DAILY STREAK")
                    .font(DrawnToBattleTypography.display(24))
                    .foregroundStyle(.white)
                Text("\(game.dailyStreak) DAY\(game.dailyStreak == 1 ? "" : "S") IN A ROW")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.top, 6)
    }

    private var weekStrip: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(0..<GameSave.dailyRewards.count, id: \.self) { index in
                    let done = game.dailyStreak > 0 && index < game.dailyCycleDay
                    let isNext = index == game.dailyCycleDay && !game.claimedDailyToday

                    ZStack {
                        Circle()
                            .fill(done || isNext
                                  ? Color(hex: 0xF5C451).opacity(done ? 0.9 : 0.25)
                                  : Color.white.opacity(0.08))
                        if done {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.black)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(isNext ? Color(hex: 0xF5C451) : .white.opacity(0.4))
                        }
                    }
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(isNext ? Color(hex: 0xF5C451) : Color.clear, lineWidth: 2)
                    )
                }
            }

            Text("7 DAY CYCLE  •  BIGGER REWARDS EVERY DAY")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var rewardCard: some View {
        let reward = game.nextDailyReward

        return VStack(spacing: 12) {
            Text(game.claimedDailyToday ? "NEXT REWARD" : "TODAY'S REWARD")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))

            HStack(spacing: 20) {
                rewardItem(
                    image: AnyView(Image(systemName: "circlebadge.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF5C451))),
                    value: "\(reward.coins)",
                    label: "COINS"
                )
                rewardItem(
                    image: AnyView(Image("DrawnToBattleGachaToken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 19)),
                    value: "\(reward.pens)",
                    label: "PENS"
                )
                rewardItem(
                    image: AnyView(Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: 0xA86CFF))),
                    value: "\(reward.xp)",
                    label: "XP"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x14161E)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(hex: 0xF5C451).opacity(0.35), lineWidth: 1)
        )
    }

    private func rewardItem(image: AnyView, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            image
            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private var claimButton: some View {
        Button {
            claim()
        } label: {
            Text(game.claimedDailyToday
                 ? "COME BACK TOMORROW"
                 : "CLAIM DAY \(game.dailyStreak + 1)")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(game.claimedDailyToday ? .white.opacity(0.5) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(game.claimedDailyToday
                              ? Color.white.opacity(0.1)
                              : Color(hex: 0xF5C451))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: 0xF5C451).opacity(game.claimedDailyToday ? 0.2 : 0.9),
                                lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .disabled(game.claimedDailyToday)
        .accessibilityLabel(game.claimedDailyToday
                            ? "Daily reward already claimed" : "Claim daily reward")
    }

    private func claim() {
        guard let reward = game.claimDaily() else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            claimedReward = reward
        }
        Haptics.success()
    }
}
