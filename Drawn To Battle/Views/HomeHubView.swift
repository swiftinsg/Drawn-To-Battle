import SwiftUI

// MARK: - Home hub (template layout)
//
// Profile top-left • coins/pens/settings top-right • gacha on the left •
// collection bottom-left • studio bottom-center • play bottom-right → solar system.

struct HomeHubView: View {
    @ObservedObject var game: GameSave
    @ObservedObject var studio: StudioState

    @State private var showStudio = false
    @State private var showGacha = false
    @State private var showCollection = false
    @State private var showSolar = false
    @State private var showSettings = false

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
                        showSettings = true
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: 0xF5C451))
                            VStack(alignment: .leading, spacing: 0) {
                                Text("FIGHTER")
                                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.45))
                                Text(game.username.isEmpty ? "UNNAMED" : game.username)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                        }
                        .bubbleChrome(sketchSeed: 11)
                    }
                    .buttonStyle(SquashButtonStyle())
                    .accessibilityLabel("Profile, \(game.username)")

                    Spacer(minLength: 6)

                    HStack(spacing: 5) {
                        Image(systemName: "circlebadge.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: 0xF5C451))
                        Text("\(game.coins)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .bubbleChrome(paddingX: 10, sketchSeed: 23)
                    .accessibilityLabel("Coins balance")

                    HStack(spacing: 5) {
                        Image("DrawnToBattleGachaToken")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 18)
                        Text("\(game.stardust)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .bubbleChrome(paddingX: 10, sketchSeed: 37)
                    .accessibilityLabel("Pens balance")

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(9)
                            .background(
                                SketchyRect(seed: 41)
                                    .fill(Color.black.opacity(0.55))
                            )
                            .overlay(
                                SketchyRect(seed: 41)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
                    }
                    .buttonStyle(SquashButtonStyle())
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // Left column: gacha + loadout.
                VStack(alignment: .leading, spacing: 12) {
                    MenuBubble(title: "GACHA", systemImage: "sparkles") {
                        showGacha = true
                    }

                    loadoutChip
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer()

                // Bottom row: collection • studio • play.
                HStack(alignment: .bottom, spacing: 12) {
                    MenuBubble(title: "COLLECTION", systemImage: "square.grid.2x2") {
                        showCollection = true
                    }
                    Spacer()
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
                            .stickerShadow()
                            .shadow(color: Color(hex: 0xF5C451).opacity(0.28), radius: 18, y: 4)
                            .modifier(StickerBob())
                    }
                    .buttonStyle(SquashButtonStyle())
                    .accessibilityLabel("Play — choose a boss")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
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
        .fullScreenCover(isPresented: $showSolar) {
            SolarSystemView(game: game)
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
                    Text("EQUIPPED ATTACK")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(loadoutLabel(equipped))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            } else {
                Text("No attack equipped — open COLLECTION")
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
            SketchyRect(seed: 53)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            SketchyRect(seed: 53)
                .stroke(Color.white.opacity(0.22), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
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
    /// Dark hand-cut bubble styling used across the home screen: a wobbly
    /// marker-drawn border with a little lift, so the chrome feels drawn
    /// with the sticker art.
    func bubbleChrome(paddingX: CGFloat = 12, sketchSeed: UInt64 = 7) -> some View {
        self
            .padding(.horizontal, paddingX)
            .padding(.vertical, 9)
            .background(
                SketchyRect(seed: sketchSeed)
                    .fill(Color.black.opacity(0.55))
            )
            .overlay(
                SketchyRect(seed: sketchSeed)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 5, y: 3)
    }
}

// MARK: - Menu bubble

private struct MenuBubble: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    /// Distinct seed per title so every bubble's wobble is unique but stable.
    private var seed: UInt64 {
        UInt64(abs(title.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }) % 997) + 3
    }

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
            .bubbleChrome(paddingX: 16, sketchSeed: seed)
        }
        .buttonStyle(SquashButtonStyle())
    }
}
