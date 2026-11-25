import SwiftUI

// MARK: - Settings

/// Utilities and defaults, opened from the hub's gear button.
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
            AppStyle.base.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    // Top bar.
                    HStack {
                        Button { dismiss() } label: {
                            Image("DrawnToBattleBackButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close settings")
                        Spacer()
                        Text("SETTINGS")
                            .font(DrawnToBattleTypography.display(20))
                            .foregroundStyle(.white)
                        Spacer()
                        Color.clear.frame(width: 32, height: 32)
                    }
                    .padding(.top, 12)

                    // Studio defaults.
                    section("ANIMATION STUDIO") {
                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    settingLabel("DEFAULT FPS")
                                    Spacer()
                                    Stepper("\(defaultFPS)", value: $defaultFPS, in: 1...30)
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundStyle(AppStyle.gold)
                                        .fixedSize()
                                }
                                Text("Used for new projects. Saved moves keep their own speed.")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Toggle(isOn: $defaultOnionSkin) {
                                    settingLabel("GHOST FRAMES")
                                }
                                .tint(AppStyle.gold)

                                Text("Shows neighboring frames faintly while you draw.")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.4))
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
                                .foregroundStyle(AppStyle.danger)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                                        .fill(AppStyle.danger.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                                        .stroke(AppStyle.danger.opacity(0.35), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            if resetDone {
                                Text("Progress reset! Your name and photo stay.")
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

                    // Testing aids.
                    section("TESTING") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: Binding(
                                get: { game.testUnlockAll },
                                set: { game.testUnlockAll = $0 }
                            )) {
                                settingLabel("UNLOCK ALL BOSSES")
                            }
                            .tint(AppStyle.gold)

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
                                .foregroundStyle(AppStyle.gold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                                        .fill(AppStyle.gold.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                                        .stroke(AppStyle.gold.opacity(0.35), lineWidth: 1)
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
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Reset all progress? You'll keep your name and photo, but lose your moves, coins, pens, XP and boss records.",
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

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appEyebrow(size: 11, tracking: 1.5)
            content()
        }
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.75))
            .lineSpacing(2)
    }
}
