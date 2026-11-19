import SwiftUI
import UIKit
import PhotosUI

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

    // Profile editing.
    @State private var photoItem: PhotosPickerItem?
    @State private var draftName = ""
    @State private var showRenameConfirm = false
    @State private var renameMessage: String?

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

                    // Profile: photo + paid rename.
                    section("PROFILE") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                ProfileAvatarView(data: game.profileImageData, size: 56)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("PROFILE PICTURE")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.45))

                                    PhotosPicker(selection: $photoItem, matching: .images) {
                                        Text(game.profileImageData == nil ? "CHOOSE PHOTO" : "CHANGE PHOTO")
                                            .font(.system(size: 12, weight: .black, design: .rounded))
                                            .foregroundStyle(Color(hex: 0xF5C451))
                                    }
                                    .buttonStyle(.plain)

                                    if game.profileImageData != nil {
                                        Button {
                                            game.clearProfileImage()
                                        } label: {
                                            Text("REMOVE PHOTO")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Spacer()
                            }

                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("NAME")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.45))

                                TextField("FIGHTER NAME", text: $draftName)
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.characters)
                                    .submitLabel(.done)
                                    .onChange(of: draftName) { _, newValue in
                                        if newValue.count > 14 { draftName = String(newValue.prefix(14)) }
                                        renameMessage = nil
                                    }
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

                                Button {
                                    showRenameConfirm = true
                                } label: {
                                    HStack {
                                        Text("CHANGE NAME")
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "circlebadge.fill")
                                            Text(GameSave.nameChangeCost.formatted())
                                        }
                                    }
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(canRename ? Color(hex: 0xF5C451) : Color.white.opacity(0.35))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: 0xF5C451).opacity(canRename ? 0.1 : 0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: 0xF5C451).opacity(canRename ? 0.35 : 0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(!canRename)

                                if game.coins < GameSave.nameChangeCost {
                                    Text("Need \(GameSave.nameChangeCost.formatted()) coins — you have \(game.coins).")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                if let renameMessage {
                                    Text(renameMessage)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
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
        .confirmationDialog(
            "Change your name to \(trimmedDraftName) for \(GameSave.nameChangeCost.formatted()) coins?",
            isPresented: $showRenameConfirm,
            titleVisibility: .visible
        ) {
            Button("CHANGE NAME") {
                if game.changeUsername(to: draftName) {
                    renameMessage = "Name changed. \(GameSave.nameChangeCost.formatted()) coins spent."
                } else {
                    renameMessage = "Name not changed — check your coins."
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { draftName = game.username }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                game.setProfileImage(image)
            }
        }
        .onChange(of: defaultFPS) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "DrawnToBattle.defaultFPS")
        }
        .onChange(of: defaultOnionSkin) { _, newValue in
            UserDefaults.standard.set(newValue, forKey: "DrawnToBattle.defaultOnionSkin")
        }
    }

    // MARK: Helpers

    private var trimmedDraftName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canRename: Bool {
        !trimmedDraftName.isEmpty
            && trimmedDraftName.count <= 14
            && trimmedDraftName != game.username
            && game.coins >= GameSave.nameChangeCost
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
