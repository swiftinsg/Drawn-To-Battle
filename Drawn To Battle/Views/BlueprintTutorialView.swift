import SwiftUI

// MARK: - Blueprint tutorial
//
// An "how to animate" lesson for one specific move. Shown when a blueprint is
// opened before it has been learned — the studio starts blank and the player
// builds the move themselves. Only finishing the lesson unlocks the move.

struct BlueprintTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    let blueprint: MoveBlueprint
    var onFinish: () -> Void

    @State private var step = 0

    /// Move-specific coaching for each combat technique. The player is taught
    /// the poses that make the move, not just the studio's buttons.
    private var techniqueLesson: (title: String, poses: [String]) {
        switch blueprint.technique {
        case .punch:
            return ("HOW A PUNCH WORKS", [
                "GUARD — elbows bent, both fists up near the chin.",
                "WIND-UP — pull the striking arm back and turn the shoulder.",
                "IMPACT — snap the arm straight out, fist extended toward the target."
            ])
        case .kick:
            return ("HOW A KICK WORKS", [
                "SET — shift your weight onto the standing leg.",
                "CHAMBER — lift the striking knee up toward the chest.",
                "EXTEND — drive the leg out and snap the foot forward."
            ])
        case .slam:
            return ("HOW A SLAM WORKS", [
                "RAISE — swing both arms high above the head.",
                "HOLD — stretch tall at the top of the motion.",
                "CRASH — bring both fists down hard in a single snap."
            ])
        case .spin:
            return ("HOW A SPIN WORKS", [
                "WIND — coil the torso and arms to one side.",
                "TURN — rotate the whole body through the arc on one foot.",
                "LAND — stop facing forward and settle into your stance."
            ])
        case .dash:
            return ("HOW A DASH WORKS", [
                "CROUCH — lean the torso low and load the back leg.",
                "PUSH — drive forward, stretching the lead leg out.",
                "ARRIVE — snap upright as the figure reaches its new spot."
            ])
        case .smear:
            return ("HOW A SMEAR WORKS", [
                "EXTREME POSE — push the striking limb to its furthest reach.",
                "STRETCH IT — lengthen the limb and thin the stroke into a streak.",
                "ONE FRAME — a smear lives in a single, blistering frame."
            ])
        }
    }

    private var steps: [(title: String, body: String)] {
        [
            ("YOU UNLOCKED \(blueprint.name.uppercased())",
             "\(blueprint.blurb)\n\nThis is a \(blueprint.technique.label) move. It's yours to animate — but you can't use it in battle until you've built it yourself."),

            (techniqueLesson.title,
             "A good \(blueprint.technique.label) is made from key poses. Build these three frames:\n\n"
                + techniqueLesson.poses.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")),

            ("MOVE THE JOINTS",
             "Drag the gold joint handles on the stickman to rotate each body part. Drag the whole figure to move it. Start from the first pose above, then key a frame for the next."),

            ("ADD FRAMES",
             "Tap the film-strip button to key each new pose. Your three poses become a sequence — the animation plays from one frame to the next."),

            ("PLAY & POLISH",
             "Hit play to preview the move. Use the ghost toggle to see your previous and next frames so the poses flow together. Bigger, cleaner motion means more POWER and more damage."),

            ("SAVE YOUR MOVE",
             "Your animation saves automatically as YOUR version of \(blueprint.name). Finish the lesson to unlock it — then equip it from your Collection and take it into battle."),
        ]
    }

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
