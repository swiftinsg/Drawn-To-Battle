import SwiftUI

// MARK: - Play lock overlay
//
// Shown when the fighter taps Play before animating their own move.
// Battles are locked behind hasAnimated, you can't fight with someone
// else's animation.

struct PlayLockView: View {
    let onGoToStudio: () -> Void

    var body: some View {
        ZStack {
            AppStyle.scrim.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("MAKE YOUR OWN MOVES")
                    .font(DrawnToBattleTypography.display(28))
                    .foregroundStyle(AppStyle.gold)

                Text("You currently don't have any attack animation.\nOpen the STUDIO and animate your fighter's attack first.")
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
                        .background(Capsule().fill(AppStyle.gold))
                }
                .buttonStyle(.plain)
            }
            .padding(30)
            .appModalCard()
            .padding(40)
        }
    }
}
