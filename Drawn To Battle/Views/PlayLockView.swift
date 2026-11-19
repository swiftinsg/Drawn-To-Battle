import SwiftUI

// MARK: - Play lock overlay
//
// Shown when the fighter taps Play before animating their own move.
// Battles are locked behind hasAnimated — you can't fight with someone
// else's animation.

struct PlayLockView: View {
    let onGoToStudio: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("MAKE YOUR OWN MOVE")
                    .font(DrawnToBattleTypography.display(28))
                    .foregroundStyle(Color(hex: 0xF5C451))

                Text("You can't take someone else's animation into battle.\nOpen the STUDIO and animate your fighter's attack first.")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    onGoToStudio()
                } label: {
                    Text("GO TO STUDIO")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: 260)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color(hex: 0xF5C451)))
                }
                .buttonStyle(.plain)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: 0x14161E))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
            )
            .padding(40)
        }
    }
}
