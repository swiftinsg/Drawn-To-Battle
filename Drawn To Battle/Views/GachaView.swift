import SwiftUI

// MARK: - Gacha screen

struct GachaView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    @State private var pulled: MoveBlueprint?
    @State private var isNew = false
    @State private var rolling = false
    @State private var showRates = false
    @State private var showHistory = false
    @State private var beamColor: Color = .clear
    @State private var beamOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: 0xF5C451).opacity(0.09))
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.28, y: -geo.size.height * 0.35)
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        tagline
                        machine
                        collectionProgress
                        secondaryButtons
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
                }
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
        .sheet(isPresented: $showRates) {
            DropRatesView()
        }
        .sheet(isPresented: $showHistory) {
            GachaHistoryView(game: game)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Sections

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image("DrawnToBattleBackButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .stickerShadow()
            }
            .buttonStyle(SquashButtonStyle())
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
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(SketchyRect(seed: 17).fill(Color.black.opacity(0.5)))
            .accessibilityLabel("Pens balance")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var tagline: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("SKETCH YOUR NEXT MOVE")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(2)
                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
            Text("Every pull adds a blueprint to your collection.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var machine: some View {
        let canPull = game.stardust >= Gacha.pullCost && !rolling

        return VStack(spacing: 12) {
            ZStack {
                SketchyRect(seed: 77)
                    .fill(Color(hex: 0x15171F))
                    .frame(width: 190, height: 170)
                    .overlay(
                        SketchyRect(seed: 77)
                            .stroke(Color(hex: 0xF5C451).opacity(0.5), lineWidth: 2)
                    )
                    .stickerShadow()

                if rolling {
                    ProgressView()
                        .tint(Color(hex: 0xF5C451))
                        .scaleEffect(1.4)
                } else {
                    Image("DrawnToBattleGachaToken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 76)
                        .stickerShadow()
                }

                SketchyRect(seed: 77)
                    .fill(beamColor)
                    .frame(width: 190, height: 170)
                    .opacity(beamOpacity)
                    .allowsHitTesting(false)
            }
            .modifier(StickerBob(lift: 3))

            Button {
                pull()
            } label: {
                HStack(spacing: 8) {
                    Image("DrawnToBattleGachaToken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 22)
                    Text("PULL — \(Gacha.pullCost)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                }
                .frame(maxWidth: 260)
                .padding(.vertical, 13)
                .background(
                    SketchyRect(seed: 81)
                        .fill(canPull ? Color(hex: 0xF5C451) : Color.white.opacity(0.12))
                )
                .overlay(
                    SketchyRect(seed: 81)
                        .stroke(Color(hex: 0xF5C451).opacity(canPull ? 0.9 : 0.2), lineWidth: 2)
                )
                .foregroundStyle(canPull ? Color.black : Color.white.opacity(0.5))
            }
            .buttonStyle(SquashButtonStyle())
            .disabled(!canPull)
            .accessibilityLabel("Pull a blueprint for \(Gacha.pullCost) pens")
        }
    }

    private var collectionProgress: some View {
        let total = BlueprintCatalog.all.count
        let owned = min(game.ownedBlueprints.count, total)
        let progress = total == 0 ? 0 : Double(owned) / Double(total)

        return VStack(spacing: 6) {
            HStack {
                Text("COLLECTION \(owned)/\(total)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text(owned < total ? "EVERY PULL IS NEW" : "DUPLICATES PAY COINS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(owned < total ? Color(hex: 0xF5C451).opacity(0.8) : .white.opacity(0.5))
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(Color(hex: 0xF5C451))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 5)
        }
        .padding(.horizontal, 4)
    }

    private var secondaryButtons: some View {
        HStack(spacing: 10) {
            Button {
                showRates = true
            } label: {
                secondaryChip(systemImage: "chart.bar", title: "DROP RATES")
            }
            .buttonStyle(SquashButtonStyle())

            Button {
                showHistory = true
            } label: {
                secondaryChip(systemImage: "clock.arrow.circlepath", title: "HISTORY")
            }
            .buttonStyle(SquashButtonStyle())
        }
    }

    private func secondaryChip(systemImage: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.75))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(SketchyRect(seed: UInt64(title.count + 3)).fill(Color.white.opacity(0.06)))
        .overlay(
            SketchyRect(seed: UInt64(title.count + 3))
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }

    // MARK: Actions

    private func pull() {
        guard game.spendStardust(Gacha.pullCost) else { return }
        rolling = true
        beamColor = .clear
        beamOpacity = 0
        // Suspense, then a rarity-colored beam, then the card.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let bp = Gacha.roll(owned: game.ownedBlueprints)
            beamColor = bp.rarity.color
            withAnimation(.easeIn(duration: 0.16)) { beamOpacity = 0.9 }
            if bp.rarity.stars >= 4 { Haptics.success() } else { Haptics.light() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    let new = game.registerPull(bp)
                    game.recordPull(bp, isNew: new)
                    isNew = new
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
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    Text(isNew ? "NEW BLUEPRINT!" : "DUPLICATE  +\(Gacha.duplicateRefund) COINS")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(isNew ? Color(hex: 0xF5C451) : .white.opacity(0.6))

                    VStack(spacing: 8) {
                        Text(String(repeating: "★", count: blueprint.rarity.stars))
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(blueprint.rarity.color)

                        Text(blueprint.name)
                            .font(DrawnToBattleTypography.display(24))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        RaritySticker(rarity: blueprint.rarity, height: 24)

                        HStack(spacing: 8) {
                            Text(blueprint.technique.label)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))
                            Text("×\(String(format: "%.2f", blueprint.rarity.damageMultiplier)) DMG")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
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
                    .padding(20)
                    .frame(maxWidth: 320)
                    .background(
                        SketchyRect(seed: 91)
                            .fill(Color(hex: 0x14161E))
                            .overlay(
                                SketchyRect(seed: 91)
                                    .stroke(blueprint.rarity.color, lineWidth: 2)
                            )
                            .shadow(color: blueprint.rarity.color.opacity(0.4), radius: 20)
                    )

                    Button {
                        onClose()
                    } label: {
                        Text("NICE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: 200)
                            .padding(.vertical, 11)
                            .background(SketchyRect(seed: 93).fill(Color(hex: 0xF5C451)))
                    }
                    .buttonStyle(SquashButtonStyle())
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Drop rates (scrollable sheet)

private struct DropRatesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("DROP RATES")
                        .font(DrawnToBattleTypography.display(20))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close drop rates")
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: true) {
                    VStack(spacing: 8) {
                        ForEach(Rarity.allCases.reversed(), id: \.self) { rarity in
                            HStack(spacing: 10) {
                                RaritySticker(rarity: rarity, height: 20)
                                Spacer()
                                if Gacha.activeRarities.contains(rarity) {
                                    Text(String(format: "%.1f%%", rarity.weight / Gacha.totalActiveWeight * 100))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.75))
                                } else {
                                    Text("SOON")
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "circlebadge.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: 0xF5C451))
                            Text("Duplicates refund \(Gacha.duplicateRefund) coins — only once the collection is complete")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .padding(.top, 6)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(hex: 0x0C0D12))
    }
}

// MARK: - Pull history (scrollable sheet)

private struct GachaHistoryView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PULL HISTORY")
                            .font(DrawnToBattleTypography.display(20))
                            .foregroundStyle(.white)
                        Text("LAST \(min(game.gachaHistory.count, 20)) PULLS")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close history")
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)

                if game.gachaHistory.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(Color(hex: 0xF5C451).opacity(0.6))
                        Text("No pulls yet")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Your last 20 pulls will appear here.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: true) {
                        LazyVStack(spacing: 8) {
                            ForEach(game.gachaHistory) { record in
                                historyRow(record)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color(hex: 0x0C0D12))
    }

    @ViewBuilder
    private func historyRow(_ record: GachaPullRecord) -> some View {
        if let bp = BlueprintCatalog.blueprint(id: record.blueprintID) {
            HStack(spacing: 10) {
                RaritySticker(rarity: bp.rarity, height: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(bp.name)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(record.isNew ? "NEW" : "DUPLICATE  +\(Gacha.duplicateRefund) COINS")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(record.isNew ? Color(hex: 0xF5C451) : .white.opacity(0.45))
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(record.date, style: .time)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(record.date, style: .date)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(bp.rarity.color.opacity(0.08)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(bp.rarity.color.opacity(0.25), lineWidth: 1)
            )
        }
    }
}
