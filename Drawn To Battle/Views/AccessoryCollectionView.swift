import SwiftUI

/// Browse every accessory, equip the ones you own, and see how to earn the rest.
struct AccessoryCollectionView: View {
    @ObservedObject var game: GameSave

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("ACCESSORIES")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
                Text("World drops and level rewards. Equip one to dress your fighter.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Accessory.allCases) { accessory in
                accessoryRow(accessory)
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

    private func accessoryRow(_ accessory: Accessory) -> some View {
        let owned = game.isAccessoryOwned(accessory)
        let equipped = game.equippedAccessory == accessory

        return HStack(spacing: 12) {
            ZStack {
                FighterFigureView(accessory: accessory)
                    .frame(width: 66, height: 88)
                    .opacity(owned ? 1 : 0.12)
                if !owned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(width: 66, height: 88)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(owned ? 0.06 : 0.02))
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(accessory.name.uppercased())
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(owned ? .white : .white.opacity(0.45))

                Text(unlockHint(accessory))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(owned ? .white.opacity(0.6) : accessory.tint.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                if owned {
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
        .opacity(owned ? 1 : 0.8)
    }

    private func unlockHint(_ accessory: Accessory) -> String {
        if game.isAccessoryOwned(accessory) { return accessory.subtitle }
        if let planet = accessory.planetName {
            return "Win the \(planet) boss or draw in its accessory gacha."
        }
        if let level = accessory.milestoneLevel {
            return "Reach level \(level) to unlock."
        }
        return "Keep playing to unlock."
    }
}
