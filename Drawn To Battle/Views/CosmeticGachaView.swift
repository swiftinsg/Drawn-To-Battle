import SwiftUI

private struct CosmeticDrawResult: Identifiable {
    let id = UUID()
    let accessory: Accessory
    let isNew: Bool
}

/// One world's cosmetic gacha. Beating the world's boss opens it; draws cost
/// coins and can return any cosmetic from that planet's themed pool.
struct CosmeticGachaView: View {
    @ObservedObject var game: GameSave
    let bossID: String

    @State private var rolling = false
    @State private var result: CosmeticDrawResult?

    private var planetName: String {
        switch bossID {
        case "earth": return "EARTH"
        case "mars": return "URANUS"
        default: return "SUN"
        }
    }

    private var tint: Color {
        switch bossID {
        case "earth": return Color(hex: 0x4ED36E)
        case "mars": return Color(hex: 0x4FC3F7)
        default: return Color(hex: 0xF5C451)
        }
    }

    private var pool: [Accessory] { Accessory.pool(forBoss: bossID) }

    private var ownedCount: Int { pool.filter { game.isAccessoryOwned($0) }.count }

    private var unlocked: Bool { game.isAccessoryGachaUnlocked(bossID: bossID) }

    private var canDraw: Bool { unlocked && game.coins >= Gacha.accessoryPullCost && !rolling }

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(planetName) COSMETIC DRAW")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(tint)
                Text(unlocked
                     ? "Win gear from \(planetName). Duplicate pieces pay coins."
                     : "Defeat the \(planetName) boss to open this gacha.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !unlocked {
                lockedCard
            } else {
                machine
                poolPreview
            }
        }
        .overlay {
            if let result {
                CosmeticResultCard(accessory: result.accessory, isNew: result.isNew,
                                    game: game) { self.result = nil }
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
    }

    private var lockedCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(tint.opacity(0.7))
            Text("LOCKED")
                .font(DrawnToBattleTypography.display(22))
                .foregroundStyle(.white)
            Text("DEFEAT THE \(planetName) BOSS")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x15171F)))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
    }

    private var machine: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: 0x15171F))
                    .frame(width: 190, height: 170)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(tint.opacity(0.6), lineWidth: 2)
                    )

                if rolling {
                    ProgressView()
                        .tint(tint)
                        .scaleEffect(1.4)
                } else {
                    GachaMachineIcon()
                        .frame(width: 132, height: 132)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "circlebadge.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF5C451))
                Text("DRAW \(Gacha.accessoryPullCost)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(canDraw ? Color(hex: 0xF5C451) : Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tint.opacity(canDraw ? 0.9 : 0.25), lineWidth: 2)
            )
            .foregroundStyle(canDraw ? Color.black : Color.white.opacity(0.5))
            .contentShape(Rectangle())
            .onTapGesture(perform: draw)
            .disabled(!canDraw)
            .accessibilityLabel("Draw a cosmetic for \(Gacha.accessoryPullCost) coins")

            HStack {
                Text("COLLECTED \(ownedCount)/\(pool.count)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text("COINS \(game.coins)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))
            }
            .padding(.horizontal, 4)
        }
    }

    private var poolPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("POSSIBLE DROPS")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.6))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pool) { accessory in
                        VStack(spacing: 3) {
                            FighterFigureView(accessory: accessory)
                                .frame(width: 44, height: 56)
                            Text(accessory.name.uppercased())
                                .font(.system(size: 7, weight: .black, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(game.isAccessoryOwned(accessory)
                                                 ? tint : .white.opacity(0.55))
                                .lineLimit(2)
                        }
                        .frame(width: 58)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05)))
                    }
                }
            }
        }
    }

    private func draw() {
        guard canDraw, let drawn = pool.randomElement() else { return }
        game.spendCoins(Gacha.accessoryPullCost)
        rolling = true
        result = nil
        Haptics.light()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let isNew = game.addAccessory(drawn)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                result = CosmeticDrawResult(accessory: drawn, isNew: isNew)
                rolling = false
            }
            if isNew { Haptics.success() }
        }
    }
}

// MARK: - Result

private struct CosmeticResultCard: View {
    let accessory: Accessory
    let isNew: Bool
    @ObservedObject var game: GameSave
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 10) {
                Text(isNew ? "NEW COSMETIC" : "DUPLICATE  +\(Gacha.accessoryDuplicateRefund) COINS")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(isNew ? accessory.tint : .white.opacity(0.6))

                FighterFigureView(accessory: accessory)
                    .frame(width: 110, height: 140)

                Text(accessory.name.uppercased())
                    .font(DrawnToBattleTypography.display(20))
                    .foregroundStyle(.white)

                Text(accessory.subtitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)

                if game.isAccessoryOwned(accessory) && game.equippedAccessory != accessory {
                    Button {
                        game.equip(accessory: accessory)
                    } label: {
                        Text("EQUIP")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: 160)
                            .padding(.vertical, 9)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color(hex: 0xF5C451)))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onClose) {
                    Text("CONTINUE")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: 160)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            .padding(22)
            .frame(maxWidth: 300)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: 0x14161E))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(accessory.tint, lineWidth: 2)
                    )
            )
        }
    }
}
