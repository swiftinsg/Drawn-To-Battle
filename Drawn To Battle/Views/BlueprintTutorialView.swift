import SwiftUI

// MARK: - Blueprint tutorial
//
// "How to animate" walkthrough, shown when a blueprint is opened for the
// first time, instead of a pre-made base animation. The studio starts blank
// and you build the move yourself.

struct BlueprintTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    var onFinish: () -> Void

    @State private var step = 0

    private let steps: [(title: String, body: String)] = [
        ("YOUR BLUEPRINT",
         "Blueprints are the moves you animate and equip in battle. Here you learn to make your own from a blank canvas."),

        ("MOVE THE JOINTS",
         "Drag any joint handle on the stickman to rotate that part. Drag the whole figure to move it. Every change updates your frame live."),

        ("ADD FRAMES",
         "Tap the film-strip button to key a new pose. String poses together and you've got your animation."),

        ("PLAY IT BACK",
         "Hit the play button to preview your move at the speed you choose. The ghost toggle shows red past frames and a blue next frame."),

        ("THE POWER METER",
         "Animation quality drives damage. The POWER readout in the studio tells you how good your move is right now."),

        ("SAVE YOUR MOVE",
         "Your animation saves automatically. It becomes the equipped move in battle, and you can animate again anytime to improve it."),
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
                                .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
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
                            onFinish()
                        } label: {
                            Text("I'M READY TO ANIMATE")
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
}
