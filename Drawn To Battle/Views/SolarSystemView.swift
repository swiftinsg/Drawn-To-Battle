import SwiftUI

// MARK: - Solar system (boss selection)

/// Full-screen view of the solar system. Each boss's planet is tappable and
/// launches its battle; locked planets are dimmed with a lock.
struct SolarSystemView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    @State private var activeBoss: BossDefinition?

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            StarField()

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
                    Text("SOLAR SYSTEM")
                        .font(DrawnToBattleTypography.display(20))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

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

                // The system itself.
                GeometryReader { geo in
                    let mid = geo.size.width / 2
                    ZStack {
                        // Orbits (decorative dashed rings).
                        OrbitRing(width: geo.size.width * 0.94, height: geo.size.width * 0.62)
                            .offset(y: geo.size.height * 0.08)
                        OrbitRing(width: geo.size.width * 0.6, height: geo.size.width * 0.38)
                            .offset(y: -geo.size.height * 0.06)

                        // The Sun, the system's star and final boss.
                        planetNode("sun", size: 108)
                            .position(x: mid, y: geo.size.height * 0.26)

                        // Inner planets.
                        planetNode("earth", size: 64)
                            .position(x: mid - geo.size.width * 0.26, y: geo.size.height * 0.68)

                        planetNode("mars", size: 56)
                            .position(x: mid + geo.size.width * 0.26, y: geo.size.height * 0.74)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
            }
        }
        .fullScreenCover(item: $activeBoss) { boss in
            BattleView(boss: boss, game: game) {
                activeBoss = nil
            }
        }
    }

    private func planetNode(_ id: String, size: CGFloat) -> some View {
        let boss = BossDefinition.boss(id: id)!
        return PlanetNode(
            boss: boss,
            unlocked: game.isUnlocked(boss),
            defeated: game.defeatedBosses.contains(id),
            size: size
        ) {
            activeBoss = boss
        }
    }

    private var nextGoalText: String {
        let allDefeated = BossDefinition.all.allSatisfy { game.defeatedBosses.contains($0.id) }
        if allDefeated {
            return "ALL PLANETS CONQUERED, YOU ARE A LEGEND"
        }

        guard let next = BossDefinition.all.first(where: { !game.defeatedBosses.contains($0.id) }) else {
            return "THE GALAXY AWAITS"
        }
        if let prereqID = next.unlockAfter,
           !game.defeatedBosses.contains(prereqID),
           let prereq = BossDefinition.boss(id: prereqID) {
            return "DEFEAT \(prereq.planetName) TO UNLOCK \(next.planetName)"
        }
        return "\(next.planetName) AWAITS"
    }
}

// MARK: - Planet node

private struct PlanetNode: View {
    let boss: BossDefinition
    let unlocked: Bool
    let defeated: Bool
    let size: CGFloat
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                ZStack {
                    // Atmosphere glow.
                    Circle()
                        .fill(Color(hex: boss.accentColor).opacity(0.16))
                        .frame(width: size * 1.6, height: size * 1.6)
                        .blur(radius: 12)

                    Circle()
                        .fill(Color(hex: boss.bodyColor))
                        .frame(width: size, height: size)
                    Circle()
                        .stroke(Color(hex: boss.accentColor).opacity(0.65), lineWidth: 2.5)
                        .frame(width: size + 12, height: size + 12)

                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: size * 0.24, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    if defeated {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(Color(hex: 0x5FBF6E)))
                            .offset(x: size * 0.38, y: -size * 0.38)
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
        }
        .buttonStyle(.plain)
        .opacity(unlocked ? 1 : 0.55)
        .disabled(!unlocked)
        .accessibilityLabel("\(boss.planetName), \(unlocked ? "available" : "locked")")
    }
}

// MARK: - Orbit ring

private struct OrbitRing: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Ellipse()
            .stroke(Color.white.opacity(0.09), style: StrokeStyle(lineWidth: 1, dash: [4, 8]))
            .frame(width: width, height: height)
    }
}

// MARK: - Star field

private struct StarField: View {
    var body: some View {
        Canvas { context, size in
            // Deterministic pseudo-random star sprinkle.
            var seed: UInt64 = 0xD7B
            func next() -> Double {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return Double((seed >> 33) & 0xFFFF) / Double(0xFFFF)
            }
            for _ in 0..<70 {
                let x = next() * size.width
                let y = next() * size.height
                let r = 0.6 + next() * 1.1
                let alpha = 0.12 + next() * 0.3
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                             with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}
