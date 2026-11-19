import SwiftUI
import UIKit

/// Circular fighter avatar used in the hub and settings. Falls back to the
/// standard person glyph when no photo has been chosen yet.
struct ProfileAvatarView: View {
    let data: Data?
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(hex: 0xF5C451))
                    .padding(size * 0.1)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        .accessibilityLabel("Profile picture")
    }
}
