import SwiftUI

// MARK: - Home hub (template layout)
//
// Profile top-left • coins/pens/settings top-right • gacha/studio/collection
// stacked down the left • play bottom-right → solar system.

struct HomeHubView: View {
    @ObservedObject var game: GameSave
    @ObservedObject var studio: StudioState

    @State private var showStudio = false
    @State private var showGacha = false
    @State private var showCollection = false
    @State private var showSolar = false
    @State private var showSettings = false
    @State private var showProfile = false
    @State private var activeCurrency: Currency?

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            HubBackdrop()

            VStack(spacing: 0) {
                // Top row: profile • coins, pens, settings.
                HStack(spacing: 7) {
                    Button {
                        showProfile = true
                    } label: {
                        HStack(spacing: 7) {
                            ProfileAvatarView(data: game.profileImageData, size: 22)
                            VStack(alignment: .leading, spacing: 0) {
                                Text("FIGHTER")
                                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.45))
                                Text(game.username.isEmpty ? "NO NAME" : game.username)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        .bubbleChrome()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Profile, \(game.username)")

                    Spacer(minLength: 6)

                    Button {
                        activeCurrency = .coins
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "circlebadge.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: 0xF5C451))
                            Text("\(game.coins)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .bubbleChrome(paddingX: 10)
                    .accessibilityLabel("Coins, tap for details")

                    Button {
                        activeCurrency = .pens
                    } label: {
                        HStack(spacing: 5) {
                            Image("DrawnToBattleGachaToken")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 18)
                            Text("\(game.stardust)")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .bubbleChrome(paddingX: 10)
                    .accessibilityLabel("Pens, tap for details")

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(9)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.55))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // Left column: the three main menus in standard order.
                VStack(alignment: .leading, spacing: 10) {
                    MenuBubble(title: "GACHA", systemImage: "sparkles") {
                        showGacha = true
                    }
                    MenuBubble(title: "STUDIO", systemImage: "film") {
                        showStudio = true
                    }
                    MenuBubble(title: "COLLECTION", systemImage: "square.grid.2x2") {
                        showCollection = true
                    }

                    loadoutChip
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer()

                // Bottom row: play → solar system.
                HStack(alignment: .bottom, spacing: 12) {
                    Spacer()
                    Button {
                        showSolar = true
                    } label: {
                        Image("DrawnToBattlePlayButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 148, height: 79)
                            .shadow(color: Color(hex: 0xF5C451).opacity(0.3), radius: 16, y: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Battle — choose a boss")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }

            if let currency = activeCurrency {
                CurrencyInfoCard(currency: currency) { activeCurrency = nil }
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: activeCurrency)
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
        .fullScreenCover(isPresented: $showSolar) {
            SolarSystemView(game: game)
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(game: game)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(game: game)
                .presentationBackground(Color(hex: 0x0C0D12))
        }
    }

    private var loadoutChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(hex: 0xF5C451))
            if let equipped = game.equipped {
                VStack(alignment: .leading, spacing: 1) {
                    Text("EQUIPPED MOVE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(loadoutLabel(equipped))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            } else {
                Text("No move equipped — open COLLECTION")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text("POWER \(Int(equippedAnalysis.power))")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: 0xF5C451))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
        .frame(maxWidth: 250)
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

    private var equippedAnalysis: AnalysisResult {
        AnimationAnalysis.analyze(game.equipped?.project ?? PoseTemplate.animation(for: .punch, name: "x"))
    }
}

// MARK: - Hub backdrop

/// Faint star field, orbit, planets and a stickman silhouette so the hub
/// doesn't read as a flat black screen.
private struct HubBackdrop: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let gold = Color(hex: 0xF5C451)

                // Warm corner glow, drawn behind everything else.
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: size.width * 0.42,
                        y: -size.height * 0.34,
                        width: size.width * 0.95,
                        height: size.height * 0.95
                    )),
                    with: .color(gold.opacity(0.07))
                )

                // Star field.
                var rng = SeededRandom(seed: 119)
                for _ in 0..<44 {
                    let x = CGFloat(rng.next()) * size.width
                    let y = CGFloat(rng.next()) * size.height
                    let radius = CGFloat(0.7 + rng.next() * 1.3)
                    let opacity = 0.08 + rng.next() * 0.2
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: x - radius, y: y - radius,
                            width: radius * 2, height: radius * 2
                        )),
                        with: .color(.white.opacity(opacity))
                    )
                }

                // Orbit.
                context.stroke(
                    Path(ellipseIn: CGRect(
                        x: -size.width * 0.12,
                        y: size.height * 0.22,
                        width: size.width * 1.22,
                        height: size.height * 0.78
                    )),
                    with: .color(.white.opacity(0.06)),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 10])
                )

                // The three boss planets.
                let planets: [(CGFloat, CGFloat, CGFloat, UInt32, UInt32)] = [
                    (0.30, 0.72, 22, 0x3FA65C, 0x4C8DFF),
                    (0.53, 0.23, 14, 0xF5C451, 0xFF8A3C),
                    (0.82, 0.60, 28, 0x4FC3F7, 0xB3E5FC),
                ]
                for planet in planets {
                    let x = planet.0 * size.width
                    let y = planet.1 * size.height
                    let d = planet.2
                    let body = Color(hex: planet.3)
                    let accent = Color(hex: planet.4)

                    context.fill(
                        Path(ellipseIn: CGRect(x: x - d * 1.7, y: y - d * 1.7,
                                               width: d * 3.4, height: d * 3.4)),
                        with: .color(accent.opacity(0.08))
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - d / 2, y: y - d / 2,
                                               width: d, height: d)),
                        with: .color(body.opacity(0.55))
                    )
                    context.stroke(
                        Path(ellipseIn: CGRect(x: x - d / 2 - 3, y: y - d / 2 - 3,
                                               width: d + 6, height: d + 6)),
                        with: .color(accent.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 1.5)
                    )
                }

                // Fighter silhouette — visible, but still behind the controls.
                let cx = size.width * 0.64
                let cy = size.height * 0.58
                let ink = Color.white.opacity(0.18)

                var torso = Path()
                torso.move(to: CGPoint(x: cx, y: cy - 50))
                torso.addLine(to: CGPoint(x: cx, y: cy + 20))

                var arms = Path()
                arms.move(to: CGPoint(x: cx, y: cy - 32))
                arms.addLine(to: CGPoint(x: cx - 36, y: cy - 18))
                arms.move(to: CGPoint(x: cx, y: cy - 32))
                arms.addLine(to: CGPoint(x: cx + 36, y: cy - 46))

                var legs = Path()
                legs.move(to: CGPoint(x: cx, y: cy + 20))
                legs.addLine(to: CGPoint(x: cx - 28, y: cy + 66))
                legs.move(to: CGPoint(x: cx, y: cy + 20))
                legs.addLine(to: CGPoint(x: cx + 26, y: cy + 66))

                let stroke = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                context.stroke(torso, with: .color(ink), style: stroke)
                context.stroke(arms, with: .color(ink), style: stroke)
                context.stroke(legs, with: .color(ink), style: stroke)
                context.fill(
                    Path(ellipseIn: CGRect(x: cx - 18, y: cy - 84, width: 36, height: 36)),
                    with: .color(ink)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// Helper so AnimationStudioView can be shown over the hub.
private struct StudioBackgroundRemoval: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Bubble chrome (the dark rounded bubbles from the home template)

extension View {
    /// Dark rounded-bubble styling used across the home screen.
    func bubbleChrome(paddingX: CGFloat = 12) -> some View {
        self
            .padding(.horizontal, paddingX)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

// MARK: - Menu bubble

private struct MenuBubble: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF5C451))
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .bubbleChrome(paddingX: 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Currency info popover

private enum Currency: String, Identifiable {
    case coins
    case pens

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coins: return "COINS"
        case .pens: return "PENS"
        }
    }

    var description: String {
        switch self {
        case .coins:
            return "Earned from battles. Spend them on things like changing your fighter's name."
        case .pens:
            return "Earned from battles. Spend them on gacha draws."
        }
    }
}

private struct CurrencyInfoCard: View {
    let currency: Currency
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    icon
                    Text(currency.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }

                Text(currency.description)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    dismiss()
                } label: {
                    Text("OK")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color(hex: 0xF5C451)))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .frame(maxWidth: 300)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x15161D)))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(hex: 0xF5C451).opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch currency {
        case .coins:
            Image(systemName: "circlebadge.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: 0xF5C451))
        case .pens:
            Image("DrawnToBattleGachaToken")
                .resizable()
                .scaledToFit()
                .frame(height: 18)
        }
    }
}
