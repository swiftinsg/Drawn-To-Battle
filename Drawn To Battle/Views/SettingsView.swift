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
                                Text("Progress reset. Your fighter keeps their name and photo.")
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
            "Reset all progress? Your fighter keeps their name and photo, but blueprints, coins, pens and boss records are wiped.",
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
}
