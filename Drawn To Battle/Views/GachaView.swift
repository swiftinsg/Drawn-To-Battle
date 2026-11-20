import SwiftUI

private struct GachaDrawResult: Identifiable {
    let id = UUID()
    let blueprint: MoveBlueprint
    let isNew: Bool
}

private enum GachaTab: Hashable {
    case moves
    case earth
    case uranus
    case sun

    var bossID: String? {
        switch self {
        case .moves: return nil
        case .earth: return "earth"
        case .uranus: return "mars"
        case .sun: return "sun"
        }
    }

    var title: String {
        switch self {
        case .moves: return "BLUEPRINT DRAW"
        case .earth: return "EARTH DRAW"
        case .uranus: return "URANUS DRAW"
        case .sun: return "SUN DRAW"
        }
    }

    var label: String {
        switch self {
        case .moves: return "MOVES"
        case .earth: return "EARTH"
        case .uranus: return "URANUS"
        case .sun: return "SUN"
        }
    }

    static let all: [GachaTab] = [.moves, .earth, .uranus, .sun]
}

// MARK: - Gacha screen

struct GachaView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss
    /// Opens the studio lesson for a newly unlocked move.
    var onLearn: ((MoveBlueprint) -> Void)? = nil

    @State private var results: [GachaDrawResult] = []
    @State private var rolling = false
    @State private var showRates = false
    @State private var showHistory = false
    @State private var beamColor: Color = .clear
    @State private var beamOpacity: Double = 0
    @State private var tab: GachaTab = .moves

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

                tabStrip
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if tab == .moves {
                            tagline
                            machine
                            collectionProgress
                            secondaryButtons
                        } else if let bossID = tab.bossID {
                            CosmeticGachaView(game: game, bossID: bossID)
                                .id(bossID)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                }
            }
        }
        .overlay {
            if results.count == 1, let first = results.first {
                GachaResultCard(blueprint: first.blueprint, isNew: first.isNew, onLearn: onLearn) {
                    results = []
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else if !results.isEmpty {
                GachaBatchResultView(results: results, onLearn: onLearn) {
                    results = []
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showRates) {
            DropRatesView()
        }
        .sheet(isPresented: $showHistory) {
            GachaHistoryView(game: game)
        }
        .onChange(of: tab) { _, _ in results = [] }
        .preferredColorScheme(.dark)
    }

    private var availableDraws: Int { game.stardust / Gacha.pullCost }

    private var tabStrip: some View {
        HStack(spacing: 6) {
            ForEach(GachaTab.all, id: \.self) { item in
                Button {
                    tab = item
                } label: {
                    Text(item.label)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(tab == item
                                         ? Color.black : Color.white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(tab == item
                                      ? Color(hex: 0xF5C451)
                                      : Color.white.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Sections

    private var topBar: some View {
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

            Text(tab.title)
                .font(DrawnToBattleTypography.display(20))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 5) {
                if tab == .moves {
                    Image("DrawnToBattleGachaToken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                    Text("\(game.stardust)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "circlebadge.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF5C451))
                    Text("\(game.coins)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5)))
            .accessibilityLabel(tab == .moves ? "Pens balance" : "Coin balance")
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
            Text("Every draw adds a move to your collection.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var machine: some View {
        let canDrawOne = availableDraws >= 1 && !rolling
        let canDrawTen = availableDraws >= 10 && !rolling
        let tenCost = 10 * Gacha.pullCost

        return VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: 0x15171F))
                    .frame(width: 190, height: 170)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: 0xF5C451).opacity(0.5), lineWidth: 2)
                    )

                if rolling {
                    ProgressView()
                        .tint(Color(hex: 0xF5C451))
                        .scaleEffect(1.4)
                } else {
                    Image("DrawnToBattleGachaMachine")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 132, height: 132)
                }

                RoundedRectangle(cornerRadius: 20)
                    .fill(beamColor)
                    .frame(width: 190, height: 170)
                    .opacity(beamOpacity)
                    .allowsHitTesting(false)
            }

            HStack(spacing: 10) {
                drawButton(
                    title: "DRAW 1",
                    cost: Gacha.pullCost,
                    enabled: canDrawOne
                ) { pull(1) }

                drawButton(
                    title: "DRAW 10",
                    cost: tenCost,
                    enabled: canDrawTen
                ) { pull(10) }
            }
        }
    }

    private func drawButton(
        title: String,
        cost: Int,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    Image("DrawnToBattleGachaToken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                    Text(title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text("\(cost) PENS")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(enabled ? Color(hex: 0xF5C451) : Color.white.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: 0xF5C451).opacity(enabled ? 0.9 : 0.2), lineWidth: 2)
            )
            .foregroundStyle(enabled ? Color.black : Color.white.opacity(0.5))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel("\(title), \(cost) pens")
    }

    private var collectionProgress: some View {
        let total = BlueprintCatalog.all.count
        let owned = min(game.ownedBlueprints.count, total)
        let progress = total == 0 ? 0 : Double(owned) / Double(total)

        return VStack(spacing: 6) {
            HStack {
                Text("COLLECTED \(owned)/\(total)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer()
                Text(owned < total ? "ALL DRAWS ARE NEW" : "DUPLICATES = COINS")
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
            .buttonStyle(.plain)

            Button {
                showHistory = true
            } label: {
                secondaryChip(systemImage: "clock.arrow.circlepath", title: "HISTORY")
            }
            .buttonStyle(.plain)
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
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: Actions

    private func pull(_ count: Int) {
        guard !rolling else { return }
        let draws = min(max(1, count), availableDraws)
        guard draws > 0, game.spendStardust(draws * Gacha.pullCost) else { return }

        results = []
        rolling = true
        beamColor = .clear
        beamOpacity = 0

        // Suspense, then a rarity-colored beam, then the result(s).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var newResults: [GachaDrawResult] = []
            var topStars = 0
            var topColor: Color = .white

            for _ in 0..<draws {
                let bp = Gacha.roll(owned: game.ownedBlueprints)
                let new = game.registerPull(bp)
                game.recordPull(bp, isNew: new)
                newResults.append(GachaDrawResult(blueprint: bp, isNew: new))
                if bp.rarity.stars > topStars {
                    topStars = bp.rarity.stars
                    topColor = bp.rarity.color
                }
            }

            beamColor = topColor
            withAnimation(.easeIn(duration: 0.16)) { beamOpacity = 0.9 }
            if topStars >= 4 { Haptics.success() } else { Haptics.light() }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                    results = newResults
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
    var onLearn: ((MoveBlueprint) -> Void)? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    Text(isNew ? "NEW MOVE!" : "DUPLICATE!  +\(Gacha.duplicateRefund) COINS")
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
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: 0x14161E))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(blueprint.rarity.color, lineWidth: 2)
                            )
                            .shadow(color: blueprint.rarity.color.opacity(0.4), radius: 20)
                    )

                    if isNew, let onLearn {
                        Button {
                            onLearn(blueprint)
                        } label: {
                            Text("LEARN THIS MOVE")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: 200)
                                .padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xF5C451)))
                        }
                        .buttonStyle(.plain)

                        Text("New moves can't be equipped until you animate them in the studio.")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        onClose()
                    } label: {
                        Text(isNew && onLearn != nil ? "MAYBE LATER" : "CONTINUE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: 200)
                            .padding(.vertical, 11)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Multi-draw results

private struct GachaBatchResultView: View {
    let results: [GachaDrawResult]
    var onLearn: ((MoveBlueprint) -> Void)? = nil
    let onClose: () -> Void

    private var newCount: Int { results.filter { $0.isNew }.count }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Text("\(results.count) DRAWS")
                        .font(DrawnToBattleTypography.display(28))
                        .foregroundStyle(Color(hex: 0xF5C451))

                    Text("\(newCount) NEW  •  \(results.count - newCount) DUPLICATES")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))

                    if newCount > 0, onLearn != nil {
                        Text("NEW MOVES ARE LESSONS — TAP LEARN ON A CARD TO ANIMATE IT")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 92), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(results) { result in
                            batchCard(result)
                        }
                    }

                    Button {
                        onClose()
                    } label: {
                        Text("CONTINUE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: 220)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0xF5C451)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func batchCard(_ result: GachaDrawResult) -> some View {
        let blueprint = result.blueprint
        return VStack(spacing: 5) {
            Text(String(repeating: "★", count: blueprint.rarity.stars))
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(blueprint.rarity.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(blueprint.name)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(blueprint.technique.label)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Text(result.isNew ? "NEW" : "+\(Gacha.duplicateRefund) COINS")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(result.isNew ? Color(hex: 0xF5C451) : .white.opacity(0.45))

            if result.isNew, let onLearn {
                Button {
                    onLearn(blueprint)
                } label: {
                    Text("LEARN")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0xF5C451)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x14161E)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(blueprint.rarity.color.opacity(0.6), lineWidth: 1.5)
        )
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
                        ForEach(Rarity.allCases.filter { $0 != .base }.reversed(), id: \.self) { rarity in
                            HStack(spacing: 10) {
                                RaritySticker(rarity: rarity, height: 20)
                                Spacer()
                                if Gacha.activeRarities.contains(rarity) {
                                    Text(String(format: "%.1f%%", rarity.weight / Gacha.totalActiveWeight * 100))
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.75))
                                } else {
                                    Text("COMING SOON")
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
                            Text("Base moves are starters. Duplicates pay coins.")
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
                        Text("DRAW HISTORY")
                            .font(DrawnToBattleTypography.display(20))
                            .foregroundStyle(.white)
                        Text("LAST \(min(game.gachaHistory.count, 20)) DRAWS")
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
                        Text("NO DRAWS YET")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Your 20 most recent draws will show up here.")
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
                    Text(record.isNew ? "NEW" : "DUPLICATE!  +\(Gacha.duplicateRefund) COINS")
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
