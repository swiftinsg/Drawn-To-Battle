import SwiftUI

// MARK: - Home hub (template layout)
//
// Profile top-left • coins/pens/settings top-right • collection on the left •
// gacha + studio bottom-left • play bottom-right → solar system.

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

                // Left column: collection + loadout.
                VStack(alignment: .leading, spacing: 12) {
                    MenuBubble(title: "COLLECTION", systemImage: "square.grid.2x2") {
                        showCollection = true
                    }

                    loadoutChip
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer()

                // Bottom row: gacha • studio • play.
                HStack(alignment: .bottom, spacing: 12) {
                    MenuBubble(title: "GACHA", systemImage: "sparkles") {
                        showGacha = true
                    }
                    MenuBubble(title: "STUDIO", systemImage: "film") {
                        showStudio = true
                    }
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
