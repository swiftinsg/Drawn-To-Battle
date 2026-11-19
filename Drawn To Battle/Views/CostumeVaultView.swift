import SwiftUI

// MARK: - Costume gacha

/// World gear is unlocked by beating that world's boss, then equipped from
/// here. The home fighter updates as soon as an accessory is equipped.
struct CostumeVaultView: View {
    @ObservedObject var game: GameSave

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("WORLD COSTUMES")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
                Text("Conquer a world to unlock its gear, then dress your fighter.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Accessory.allCases) { accessory in
                costumeRow(accessory)
            }

            Button {
                game.clearAccessory()
                Haptics.light()
            } label: {
                Text("REMOVE ACCESSORY")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(game.equippedAccessory == nil
                                     ? .white.opacity(0.35) : .white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(game.equippedAccessory == nil)
        }
    }

    private func costumeRow(_ accessory: Accessory) -> some View {
        let unlocked = game.isAccessoryUnlocked(accessory)
        let equipped = game.equippedAccessory == accessory

        return HStack(spacing: 12) {
            FighterFigureView(accessory: accessory)
                .frame(width: 66, height: 88)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(unlocked ? 0.06 : 0.02))
                )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(accessory.name.uppercased())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Text(unlocked ? accessory.subtitle : "DEFEAT \(accessory.planetName) TO UNLOCK")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(unlocked ? .white.opacity(0.6) : accessory.tint.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)

                if unlocked {
                    Button {
                        game.equip(accessory: accessory)
                        Haptics.light()
                    } label: {
                        Text(equipped ? "EQUIPPED" : "EQUIP")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(equipped ? Color.black : Color(hex: 0xF5C451))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(equipped
                                               ? Color(hex: 0xF5C451)
                                               : Color(hex: 0xF5C451).opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(equipped)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: 0x15171F)))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(equipped ? Color(hex: 0xF5C451) : Color.white.opacity(0.1),
                        lineWidth: equipped ? 2 : 1)
        )
        .opacity(unlocked ? 1 : 0.72)
    }
}
