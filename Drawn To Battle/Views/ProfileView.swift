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
            ProfileSolarDecor()

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
                    renameMessage = "Name changed! \(GameSave.nameChangeCost.formatted()) coins spent."
                } else if trimmedDraftName.count < GameSave.minNameLength {
                    renameMessage = "Use at least \(GameSave.minNameLength) characters!"
                } else if trimmedDraftName == game.username {
                    renameMessage = "That's already your name."
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
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close profile")

            Spacer()

            Text("PROFILE")
                .font(DrawnToBattleTypography.display(20))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
    }

    private var milestoneText: String {
        guard let next = Accessory.milestoneLevels.first(where: { $0 > game.level }),
              let reward = Accessory.accessory(forMilestone: next) else {
            return "ALL LEVEL REWARDS UNLOCKED"
        }
        return "NEXT REWARD \(reward.name.uppercased()) AT LV \(next)"
    }

    private var avatarAndLevel: some View {
        let progress = game.levelProgress
        let fraction = progress.needed > 0
            ? min(1, max(0, Double(progress.current) / Double(progress.needed)))
            : 0

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppStyle.gold.opacity(0.12))
                    .frame(width: 140, height: 140)
                    .blur(radius: 18)

                ProfileAvatarView(data: game.profileImageData, size: 92)
                    .overlay(
                        Circle()
                            .stroke(AppStyle.gold.opacity(0.9), lineWidth: 3)
                            .frame(width: 100, height: 100)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(AppStyle.gold)
                                .background(Circle().fill(AppStyle.base))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 4, y: 4)
                        .accessibilityLabel("Edit profile photo")
                    }
            }

            Text("LV. \(game.level)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(AppStyle.gold))

            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppStyle.hairline)
                        Capsule()
                            .fill(AppStyle.gold)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(width: 150, height: 5)

                Text("XP \(progress.current)/\(progress.needed)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.55))

                Text(milestoneText)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(AppStyle.gold.opacity(0.75))
            }
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
                .appEyebrow(size: 9, tracking: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: AppStyle.largeCorner).fill(Color.black.opacity(0.5)))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.largeCorner)
                .stroke(AppStyle.gold.opacity(0.35), lineWidth: 1)
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
                        .foregroundStyle(AppStyle.gold)
                )
            )
            statCard(
                title: "COINS",
                value: game.coins.formatted(),
                icon: AnyView(
                    Image(systemName: "circlebadge.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppStyle.gold)
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
                    if newValue.count > GameSave.maxNameLength {
                        draftName = String(newValue.prefix(GameSave.maxNameLength))
                    }
                    renameMessage = nil
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: AppStyle.mediumCorner).fill(Color.white.opacity(0.06)))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                        .stroke(AppStyle.hairline, lineWidth: 1)
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
                .foregroundStyle(canRename ? AppStyle.gold : Color.white.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                        .fill(AppStyle.gold.opacity(canRename ? 0.12 : 0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                        .stroke(AppStyle.gold.opacity(canRename ? 0.4 : 0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canRename)

            if trimmedDraftName.count < GameSave.minNameLength {
                Text("USE AT LEAST \(GameSave.minNameLength) CHARACTERS")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(AppStyle.gold.opacity(0.8))
            } else if game.coins < GameSave.nameChangeCost {
                Text("\(coinsNeeded.formatted()) MORE COINS TO GO")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(AppStyle.gold.opacity(0.8))
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
        .background(RoundedRectangle(cornerRadius: AppStyle.mediumCorner).fill(AppStyle.softHairline))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.mediumCorner)
                .stroke(AppStyle.hairline, lineWidth: 1)
        )
    }

    private var clearedCount: Int {
        BossDefinition.all.filter { game.defeatedBosses.contains($0.id) }.count
    }

    private var trimmedDraftName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var coinsNeeded: Int {
        max(0, GameSave.nameChangeCost - game.coins)
    }

    private var canRename: Bool {
        trimmedDraftName.count >= GameSave.minNameLength
            && trimmedDraftName.count <= GameSave.maxNameLength
            && trimmedDraftName != game.username
            && game.coins >= GameSave.nameChangeCost
    }
}

// MARK: - Background solar system

/// Three planets sitting along the faint orbit already drawn by
/// StartScreenBackground, so the profile reads as a mini solar system.
private struct ProfileSolarDecor: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.29)
                let radiusX = size.width * 0.41
                let radiusY = size.height * 0.14

                let orbit = Path(ellipseIn: CGRect(
                    x: center.x - radiusX,
                    y: center.y - radiusY,
                    width: radiusX * 2,
                    height: radiusY * 2
                ))
                context.stroke(
                    orbit,
                    with: .color(.white.opacity(0.07)),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                )

                // Earth, Sun, Uranus, same palette as the boss planets.
                let planets: [(CGFloat, CGFloat, CGFloat, UInt32, UInt32)] = [
                    (-0.78, 0.16, 13, 0x3FA65C, 0x4C8DFF),
                    (0.0, -1.0, 17, 0xF5C451, 0xFF8A3C),
                    (0.78, 0.16, 12, 0x4FC3F7, 0xB3E5FC),
                ]

                for planet in planets {
                    let pos = CGPoint(
                        x: center.x + planet.0 * radiusX,
                        y: center.y + planet.1 * radiusY
                    )
                    let diameter = planet.2
                    let body = Color(hex: planet.3)
                    let accent = Color(hex: planet.4)

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: pos.x - diameter * 1.5,
                            y: pos.y - diameter * 1.5,
                            width: diameter * 3,
                            height: diameter * 3
                        )),
                        with: .color(accent.opacity(0.12))
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: pos.x - diameter / 2,
                            y: pos.y - diameter / 2,
                            width: diameter,
                            height: diameter
                        )),
                        with: .color(body)
                    )
                    context.stroke(
                        Path(ellipseIn: CGRect(
                            x: pos.x - diameter / 2 - 3,
                            y: pos.y - diameter / 2 - 3,
                            width: diameter + 6,
                            height: diameter + 6
                        )),
                        with: .color(accent.opacity(0.6)),
                        style: StrokeStyle(lineWidth: 1.5)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
