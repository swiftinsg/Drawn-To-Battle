import SwiftUI

// MARK: - Studio tutorial
//
// First-time walkthrough of the animation studio. Shown once per fighter.

struct StudioTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    var game: GameSave?

    @State private var step = 0

    private let steps: [(title: String, body: String)] = [
        ("WELCOME TO THE STUDIO",
         "This is where you bring your stickman to life. Every bone you rotate and every frame you add becomes your fighter's attack in battle."),

        ("PICK A BONE",
         "Tap \"SELECT BONE\" at the top, then choose a joint — arm, leg, torso or head — to move it."),

        ("POSE IT",
         "Drag the selected bone around, or use the angle slider to rotate it precisely. Your changes update the frame live."),

        ("ADD A FRAME",
         "Tap the film-strip button to add another frame. String poses together and you've got an animation."),

        ("PLAY IT",
         "Hit the play button to preview your move. Scrub the timeline to check each frame."),

        ("SAVE IT",
         "Tap the down-arrow to save. Your custom move is now equipped and ready to take into battle."),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress.
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i <= step ? Color(hex: 0xF5C451) : Color.white.opacity(0.2))
                            .frame(width: step == i ? 18 : 10, height: 6)
                    }
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 14)

                Spacer()

                // Step content.
                VStack(spacing: 16) {
                    Text("\(step + 1) / \(steps.count)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451).opacity(0.7))

                    Text(steps[step].title)
                        .font(DrawnToBattleTypography.display(24))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(steps[step].body)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Navigation.
                HStack(spacing: 16) {
                    if step > 0 {
                        Button {
                            step -= 1
                        } label: {
                            Text("BACK")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    if step < steps.count - 1 {
                        Button {
                            step += 1
                        } label: {
                            Text("NEXT")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color(hex: 0xF5C451)))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            finish()
                        } label: {
                            Text("I'M READY — ANIMATE")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color(hex: 0xF5C451)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }

    private func finish() {
        game?.hasSeenStudioTutorial = true
        dismiss()
    }
}
