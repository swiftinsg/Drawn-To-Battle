import SwiftUI

// MARK: - Gacha screen

struct GachaView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    @State private var pulled: MoveBlueprint?
    @State private var isNew = false
    @State private var rolling = false
    @State private var showRates = false
    @State private var beamColor: Color = .clear
    @State private var beamOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar.
                HStack {
                    Button { dismiss() } label: {
                        Image("DrawnToBattleBackButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    Spacer()
                    Text("BLUEPRINT GACHA")
                        .font(DrawnToBattleTypography.display(20))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 5) {
                        Image("DrawnToBattleGachaToken")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        Text("\(game.stardust)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                Spacer()

                // Machine.
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: 0x14161E))
                            .frame(width: 210, height: 210)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0xF5C451).opacity(0.4), lineWidth: 2))
                        if rolling {
                            ProgressView().tint(Color(hex: 0xF5C451))
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 64, weight: .bold))
                                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
                        }
                        // Rarity beam flash on reveal.
                        RoundedRectangle(cornerRadius: 20)
                            .fill(beamColor)
                            .frame(width: 210, height: 210)
                            .opacity(beamOpacity)
                            .allowsHitTesting(false)
                    }

                    Button {
                        pull()
                    } label: {
                        HStack(spacing: 8) {
                            Image("DrawnToBattleGachaToken")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 22)
                            Text("PULL — 100")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: 260)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(game.stardust >= Gacha.pullCost && !rolling ? Color(hex: 0xF5C451) : Color.white.opacity(0.15)))
                        .foregroundStyle(game.stardust >= Gacha.pullCost ? .black : .white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(game.stardust < Gacha.pullCost || rolling)

                    // Coin → pen exchange (battles pay coins).
                    Button {
                        guard game.coins >= Gacha.exchangeCoins else { return }
                        game.coins -= Gacha.exchangeCoins
                        game.addStardust(Gacha.exchangePens)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "circlebadge.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(Gacha.exchangeCoins) → \(Gacha.exchangePens)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                            Image("DrawnToBattleGachaToken")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 13)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(game.coins >= Gacha.exchangeCoins && !rolling ? Color.white.opacity(0.1) : Color.white.opacity(0.04)))
                        .foregroundStyle(game.coins >= Gacha.exchangeCoins ? Color(hex: 0xF5C451) : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(game.coins < Gacha.exchangeCoins || rolling)
                    .accessibilityLabel("Exchange coins for pens")

                    Button {
                        withAnimation { showRates.toggle() }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chart.bar")
                            Text("Drop rates")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                }

                if showRates {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Rarity.allCases.reversed(), id: \.self) { rarity in
                            HStack {
                                RaritySticker(rarity: rarity, height: 13)
                                Spacer()
                                if Gacha.activeRarities.contains(rarity) {
                                    Text(String(format: "%.1f%%", rarity.weight / Gacha.totalActiveWeight * 100))
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.6))
                                } else {
                                    Text("SOON")
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                        }
                        HStack(spacing: 4) {
                            Text("Duplicates refund \(Gacha.duplicateRefund)")
                            Image("DrawnToBattleGachaToken")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 11)
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                Spacer()
            }
        }
        .overlay {
            if let bp = pulled {
                GachaResultCard(blueprint: bp, isNew: isNew) {
                    pulled = nil
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
    }

    private func pull() {
        guard game.spendStardust(Gacha.pullCost) else { return }
        rolling = true
        beamColor = .clear
        beamOpacity = 0
        // Suspense, then a rarity-colored beam, then the card.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let bp = Gacha.roll()
            beamColor = bp.rarity.color
            withAnimation(.easeIn(duration: 0.16)) { beamOpacity = 0.9 }
            if bp.rarity.stars >= 4 { Haptics.success() } else { Haptics.light() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    isNew = game.registerPull(bp)
                    pulled = bp
                    rolling = false
                    beamOpacity = 0
                }
            }
        }
    }
}

// MARK: - Result card

private struct GachaResultCard: View {
    let blueprint: MoveBlueprint
    let isNew: Bool
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(isNew ? "NEW!" : "DUPLICATE +\(Gacha.duplicateRefund) ✦")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(isNew ? Color(hex: 0xF5C451) : .white.opacity(0.6))

                VStack(spacing: 10) {
                    Text(String(repeating: "★", count: blueprint.rarity.stars))
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(blueprint.rarity.color)

                    Text(blueprint.name)
                        .font(DrawnToBattleTypography.display(26))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    RaritySticker(rarity: blueprint.rarity, height: 22)

                    HStack(spacing: 8) {
                        Text(blueprint.technique.label)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
                        Text("×\(String(format: "%.2f", blueprint.rarity.damageMultiplier)) DMG")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
                    }

                    Text(blueprint.blurb)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: 320)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: 0x14161E))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(blueprint.rarity.color, lineWidth: 2)
                        )
                        .shadow(color: blueprint.rarity.color.opacity(0.45), radius: 24)
                )

                Button {
                    onClose()
                } label: {
                    Text("NICE")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color(hex: 0xF5C451)))
                }
                .buttonStyle(.plain)
            }
            .padding(30)
        }
    }
}
