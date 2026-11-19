import SwiftUI
import UIKit
import PhotosUI

// MARK: - Fighter profile

/// Standard game-style profile screen: avatar, nameplate, level and stats,
/// with editing actions separated from the rest of the settings.
struct ProfileView: View {
    @ObservedObject var game: GameSave
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var draftName = ""
    @State private var showRenameConfirm = false
    @State private var renameMessage: String?

    var body: some View {
        ZStack {
            StartScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    avatarAndLevel
                    nameplate
                    actions
                    statsRow
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { draftName = game.username }
        .confirmationDialog(
            "Change your name to \(trimmedDraftName)? Costs \(GameSave.nameChangeCost.formatted()) coins.",
            isPresented: $showRenameConfirm,
            titleVisibility: .visible
        ) {
            Button("CHANGE NAME") {
                if game.changeUsername(to: draftName) {
                    renameMessage = "Name changed! −\(GameSave.nameChangeCost.formatted()) coins."
                } else {
                    renameMessage = "Not enough coins!"
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                game.setProfileImage(image)
            }
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image("DrawnToBattleBackButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close profile")

            Spacer()

            Text("PROFILE")
                .font(DrawnToBattleTypography.display(22))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 30, height: 30)
        }
    }

    private var avatarAndLevel: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xF5C451).opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 18)

                ProfileAvatarView(data: game.profileImageData, size: 92)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: 0xF5C451).opacity(0.9), lineWidth: 3)
                            .frame(width: 100, height: 100)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color(hex: 0xF5C451))
                                .background(Circle().fill(Color(hex: 0x0C0D12)))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 4, y: 4)
                        .accessibilityLabel("Edit profile photo")
                    }
            }

            Text("LV. \(fighterLevel)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color(hex: 0xF5C451)))
        }
        .padding(.top, 2)
    }

    private var nameplate: some View {
        VStack(spacing: 3) {
            Text(game.username.isEmpty ? "NO NAME" : game.username)
                .font(DrawnToBattleTypography.display(26))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("FIGHTER")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.5)))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: 0xF5C451).opacity(0.35), lineWidth: 1)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(
                title: "PLANETS",
                value: "\(clearedCount)/\(BossDefinition.all.count)",
                icon: AnyView(
                    Image(systemName: "globe")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF5C451))
                )
            )
            statCard(
                title: "COINS",
                value: game.coins.formatted(),
                icon: AnyView(
                    Image(systemName: "circlebadge.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0xF5C451))
                )
            )
            statCard(
                title: "PENS",
                value: game.stardust.formatted(),
                icon: AnyView(
                    Image("DrawnToBattleGachaToken")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 16)
                )
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            TextField("NEW NAME", text: $draftName)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .submitLabel(.done)
                .onChange(of: draftName) { _, newValue in
                    if newValue.count > 14 { draftName = String(newValue.prefix(14)) }
                    renameMessage = nil
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

            Button { showRenameConfirm = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("CHANGE NAME")
                    Spacer(minLength: 2)
                    HStack(spacing: 3) {
                        Image(systemName: "circlebadge.fill")
                        Text(GameSave.nameChangeCost.formatted())
                    }
                }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(canRename ? Color(hex: 0xF5C451) : Color.white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xF5C451).opacity(canRename ? 0.12 : 0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: 0xF5C451).opacity(canRename ? 0.4 : 0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canRename)

            if game.coins < GameSave.nameChangeCost {
                Text("\(coinsNeeded.formatted()) MORE COINS TO GO")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(Color(hex: 0xF5C451).opacity(0.8))
            }

            if let renameMessage {
                Text(renameMessage)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if game.profileImageData != nil {
                Button {
                    game.clearProfileImage()
                } label: {
                    Text("REMOVE PHOTO")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Helpers

    private func statCard(title: String, value: String, icon: AnyView) -> some View {
        VStack(spacing: 4) {
            icon
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var clearedCount: Int {
        BossDefinition.all.filter { game.defeatedBosses.contains($0.id) }.count
    }

    private var fighterLevel: Int { 1 + clearedCount }

    private var trimmedDraftName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var coinsNeeded: Int {
        max(0, GameSave.nameChangeCost - game.coins)
    }

    private var canRename: Bool {
        !trimmedDraftName.isEmpty
            && trimmedDraftName.count <= 14
            && trimmedDraftName != game.username
            && game.coins >= GameSave.nameChangeCost
    }
}
