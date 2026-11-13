import SwiftUI
import UIKit

// MARK: - Rarity sticker (hand-drawn label art from the design sheet)

extension Rarity {
    var stickerImageName: String {
        switch self {
        case .base: return "RarityLabelBase"
        case .common: return "RarityLabelCommon"
        case .rare: return "RarityLabelRare"
        case .epic: return "RarityLabelEpic"
        case .mythic: return "RarityLabelMythic"
        case .legendary: return "RarityLabelLegendary"
        case .elite: return "RarityLabelElite"
        case .transcendent: return "RarityLabelTranscendent"
        case .omniscient: return "RarityLabelOmniscient"
        }
    }
}

/// Displays the drawn rarity label for a tier. Falls back to plain text if
/// the sticker art is missing.
struct RaritySticker: View {
    let rarity: Rarity
    var height: CGFloat = 14

    var body: some View {
        if UIImage(named: rarity.stickerImageName) != nil {
            Image(rarity.stickerImageName)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityLabel(rarity.label)
        } else {
            Text(rarity.label)
                .font(.system(size: height * 0.75, weight: .black, design: .rounded))
                .foregroundStyle(rarity.color)
        }
    }
}
