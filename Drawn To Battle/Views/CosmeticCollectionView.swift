import SwiftUI

/// Browse every cosmetic in two-column sections, equip the ones you own, and
/// see how to earn the rest.
struct CosmeticCollectionView: View {
    @ObservedObject var game: GameSave

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("COSMETICS")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color(hex: 0xF5C451).opacity(0.85))
                Text("World drops and trophy rewards. Tap one to dress your fighter.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(CosmeticSection.allCases) { section in
                let items = Accessory.allCases.filter { $0.collectionSection == section }
                if !items.isEmpty {
                    sectionBlock(section: section, items: items)
                }
            }

            Button {
                game.clearAccessory()
                Haptics.light()
            } label: {
                Text("REMOVE COSMETIC")
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

    private func sectionBlock(section: CosmeticSection, items: [Accessory]) -> some View {
        let owned = items.filter { game.isAccessoryOwned($0) }.count
        let tint = sectionTint(section)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(section.rawValue)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(tint)

                Rectangle()
                    .fill(tint.opacity(0.35))
                    .frame(height: 1)

                Text("\(owned)/\(items.count)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
            }

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { accessory in
                    cosmeticCell(accessory)
                }
            }
        }
    }

    private func cosmeticCell(_ accessory: Accessory) -> some View {
        let owned = game.isAccessoryOwned(accessory)
        let equipped = game.equippedAccessory == accessory

        return Button {
            guard owned else { return }
            if equipped {
                game.clearAccessory()
            } else {
                game.equip(accessory: accessory)
            }
            Haptics.light()
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    FighterFigureView(accessory: accessory)
                        .frame(width: 128, height: 152)
                        .opacity(owned ? 1 : 0.14)

                    Text(accessory.name.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(owned ? .white : .white.opacity(0.5))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)

                    Text(unlockHint(accessory))
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(owned
                                         ? .white.opacity(0.55)
                                         : accessory.tint.opacity(0.85))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.vertical, 10)

                if !owned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                        .padding(6)
                } else if equipped {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color(hex: 0xF5C451))
                        .padding(4)
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: equipped ? 0x201D14 : 0x15171F))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(equipped
                            ? Color(hex: 0xF5C451)
                            : Color.white.opacity(owned ? 0.1 : 0.05),
                            lineWidth: equipped ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel(accessory.name + ", " +
                            (owned ? (equipped ? "equipped, tap to remove" : "equip")
                                   : unlockHint(accessory)))
    }

    private func unlockHint(_ accessory: Accessory) -> String {
        if game.isAccessoryOwned(accessory) { return accessory.subtitle }
        if let planet = accessory.planetName {
            return "\(planet) GACHA"
        }
        if let level = accessory.levelRoadLevel {
            return "TROPHY ROAD L\(level)"
        }
        if let level = accessory.milestoneLevel {
            return "LEVEL \(level) MILESTONE"
        }
        return "KEEP PLAYING"
    }

    private func sectionTint(_ section: CosmeticSection) -> Color {
        switch section {
        case .earth: return Color(hex: 0x7BD77A)
        case .uranus: return Color(hex: 0x7AD7F0)
        case .sun: return Color(hex: 0xFFB35C)
        case .trophy: return Color(hex: 0xF5C451)
        case .others: return Color.white.opacity(0.7)
        }
    }
}
