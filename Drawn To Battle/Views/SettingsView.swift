import SwiftUI

// MARK: - Settings

/// Customization + utilities sheet, opened from the home hub.
struct SettingsView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    // Studio defaults (stored in UserDefaults, read by StudioState).
    @State private var defaultFPS = AnimationProject.defaultFPS
    @State private var defaultOnionSkin = UserDefaults.standard.bool(forKey: "DrawnToBattle.defaultOnionSkin")

    @State private var showResetConfirm = false
    @State private var resetDone = false
    @State private var maxedDone = false

    var body: some View {
        ZStack {
            Color(hex: 0x0C0D12).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    // Top bar.
                    HStack {
                        Button { dismiss() } label: {
                            Image("DrawnToBattleBackButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .stickerShadow()
                        }
                        .buttonStyle(SquashButtonStyle())
                        .accessibilityLabel("Close settings")
                        Spacer()
                        Text("SETTINGS")
                            .font(DrawnToBattleTypography.display(20))
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 32, height: 32)
                    }
                    .padding(.top, 12)

                    // Fighter identity.
                    section("FIGHTER") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NAME")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                            TextField("FIGHTER NAME", text: nameBinding)
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .submitLabel(.done)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                    }

                    // Studio defaults.
                    section("ANIMATION STUDIO") {
                        VStack(spacing: 14) {
                            HStack {
                                settingLabel("DEFAULT FPS\nFOR NEW PROJECTS")
                                Spacer()
                                Stepper("\(defaultFPS)", value: $defaultFPS, in: 1...30)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(Color(hex: 0xF5C451))
                                    .fixedSize()
                            }
                            Toggle(isOn: $defaultOnionSkin) {
                                settingLabel("ONION SKIN\nBY DEFAULT")
                            }
                            .tint(Color(hex: 0xF5C451))
                        }
                    }

                    // Currency primer.
                    section("CURRENCIES") {
                        VStack(spacing: 12) {
                            currencyRow(icon: AnyView(Image(systemName: "circlebadge.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: 0xF5C451))),
                                        title: "COINS",
                                        blurb: "Earned by beating bosses.")
                            currencyRow(icon: AnyView(Image("DrawnToBattleGachaToken")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 14)),
                                        title: "PENS",
                                        blurb: "Half of every boss reward; spent on gacha pulls.")
                        }
                    }

                    // Testing aids.
                    section("TESTING") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: Binding(
                                get: { game.testUnlockAll },
                                set: { game.testUnlockAll = $0 }
                            )) {
                                settingLabel("UNLOCK ALL BOSSES")
                            }
                            .tint(Color(hex: 0xF5C451))

                            Button {
                                game.coins = 99_999
                                game.stardust = 99_999
                                maxedDone = true
                            } label: {
                                HStack {
                                    Image(systemName: "scalemass.fill")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("MAX CURRENCIES (99,999)")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                    Spacer()
                                }
                                .foregroundStyle(Color(hex: 0xF5C451))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: 0xF5C451).opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: 0xF5C451).opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if maxedDone {
                                Text("Coins and pens set to 99,999.")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }
                    }

                    // Danger zone.
                    section("DANGER ZONE") {
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                showResetConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("RESET PROGRESS")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                    Spacer()
                                }
                                .foregroundStyle(Color(hex: 0xE86A6A))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: 0xE86A6A).opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: 0xE86A6A).opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if resetDone {
                                Text("Progress reset. Your fighter keeps their name.")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }
                    }

                    // About.
                    section("ABOUT") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DRAWN TO BATTLE")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Version \(appVersion)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Reset all progress? Your fighter keeps their name, but blueprints, coins, pens and boss records are wiped.",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("RESET PROGRESS", role: .destructive) {
                game.resetProgress()
                resetDone = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: defaultFPS) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "DrawnToBattle.defaultFPS")
        }
        .onChange(of: defaultOnionSkin) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "DrawnToBattle.defaultOnionSkin")
        }
    }

    // MARK: Helpers

    private var nameBinding: Binding<String> {
        Binding(
            get: { game.username },
            set: { newValue in
                var limited = newValue
                if limited.count > 14 { limited = String(limited.prefix(14)) }
                let trimmed = limited.trimmingCharacters(in: .whitespacesAndNewlines)
                // Keep the save valid: never blank out the name entirely.
                game.username = trimmed.isEmpty ? game.username : trimmed
            }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color(hex: 0xF5C451))
            content()
        }
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.75))
            .lineSpacing(2)
    }

    private func currencyRow(icon: AnyView, title: String, blurb: String) -> some View {
        HStack(spacing: 10) {
            icon
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(blurb)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}
