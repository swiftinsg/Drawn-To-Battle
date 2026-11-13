import SwiftUI

// MARK: - Home hub

struct HomeHubView: View {
    @ObservedObject var game: GameSave
    @ObservedObject var studio: StudioState

    @State private var showStudio = false
    @State private var showGacha = false
    @State private var showCollection = false
    @State private var activeBoss: BossDefinition?

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            // Background glow.
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: 0xF5C451).opacity(0.08))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.35, y: -geo.size.height * 0.4)
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar.
                HStack {
                    Image("DrawnToBattleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                    Spacer()
                    HStack(spacing: 5) {
                        Image("DrawnToBattleGachaToken")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                        Text("\(game.stardust)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Planet / boss selection.
                HStack(spacing: 14) {
                    ForEach(BossDefinition.all) { boss in
                        PlanetCard(boss: boss, unlocked: game.isUnlocked(boss), defeated: game.defeatedBosses.contains(boss.id)) {
                            if game.isUnlocked(boss) {
                                activeBoss = boss
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Next goal banner.
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF5C451))
                    Text(nextGoalText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 26)
                .padding(.top, 10)

                // Loadout chip.
                HStack(spacing: 10) {
                    Image(systemName: "figure.boxing")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF5C451))
                    if let equipped = game.equipped {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("EQUIPPED ATTACK")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                            Text(loadoutLabel(equipped))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    } else {
                        Text("No attack equipped — open COLLECTION")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    let analysis = equippedAnalysis
                    Text("POWER \(Int(analysis.power))")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer()

                // Main actions.
                HStack(spacing: 14) {
                    HubButton(title: "ANIMATION\nSTUDIO", systemImage: "film", style: .primary) {
                        showStudio = true
                    }
                    HubButton(title: "GACHA", systemImage: "sparkles", style: .gold) {
                        showGacha = true
                    }
                    HubButton(title: "COLLECTION", systemImage: "square.grid.2x2", style: .dark) {
                        showCollection = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .fullScreenCover(isPresented: $showStudio) {
            AnimationStudioView(studio: studio, onBack: { showStudio = false })
                .background(StudioBackgroundRemoval())
        }
        .fullScreenCover(isPresented: $showGacha) {
            GachaView(game: game)
        }
        .fullScreenCover(isPresented: $showCollection) {
            CollectionView(game: game)
        }
        .fullScreenCover(item: $activeBoss) { boss in
            BattleView(boss: boss, game: game) {
                activeBoss = nil
            }
        }
    }

    private func loadoutLabel(_ equipped: EquippedLoadout) -> String {
        switch equipped.source {
        case .blueprint(let id):
            var name = BlueprintCatalog.blueprint(id: id)?.name ?? "Blueprint"
            if game.blueprintEdits[id] != nil { name += " (edited)" }
            return name
        case .studio(let name):
            return "\"\(name)\" (custom)"
        }
    }

    private var nextGoalText: String {
        if let next = BossDefinition.all.first(where: { !game.isUnlocked($0) }) {
            if let prereqID = next.unlockAfter, let prereq = BossDefinition.boss(id: prereqID) {
                return "Beat \(prereq.bossName) to unlock \(next.planetName)"
            }
            return "\(next.planetName) awaits"
        }
        return "ALL PLANETS CONQUERED — you are legend"
    }

    private var equippedAnalysis: AnalysisResult {
        AnimationAnalysis.analyze(game.equipped?.project ?? PoseTemplate.animation(for: .punch, name: "x"))
    }
}

// Helper so AnimationStudioView can be shown over the hub.
private struct StudioBackgroundRemoval: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Planet card

private struct PlanetCard: View {
    let boss: BossDefinition
    let unlocked: Bool
    let defeated: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: boss.bodyColor))
                        .frame(width: 64, height: 64)
                    Circle()
                        .stroke(Color(hex: boss.accentColor).opacity(0.6), lineWidth: 3)
                        .frame(width: 74, height: 74)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    if defeated {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(Color(hex: 0x5FBF6E)))
                            .offset(x: 24, y: -24)
                    }
                }
                VStack(spacing: 2) {
                    Text(boss.planetName)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(unlocked ? boss.requiredTechnique.label : "LOCKED")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(unlocked ? Color(hex: 0xF5C451) : .white.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(unlocked ? 0.07 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(unlocked ? 0.14 : 0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(unlocked ? 1 : 0.55)
    }
}

// MARK: - Hub button

private struct HubButton: View {
    enum Style { case primary, gold, dark }
    let title: String
    let systemImage: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 86)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch style {
        case .primary: return Color(hex: 0x1B1E2B)
        case .gold: return Color(hex: 0xF5C451)
        case .dark: return Color.white.opacity(0.07)
        }
    }

    private var foreground: Color {
        switch style {
        case .primary: return .white
        case .gold: return .black
        case .dark: return .white.opacity(0.85)
        }
    }

    private var border: Color {
        switch style {
        case .primary: return Color(hex: 0xF5C451).opacity(0.35)
        case .gold: return .clear
        case .dark: return Color.white.opacity(0.12)
        }
    }
}
