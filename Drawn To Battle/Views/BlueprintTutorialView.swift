import SwiftUI

// MARK: - Blueprint tutorial
//
// An "how to animate" lesson for one specific move. Shown when a blueprint is
// opened before it has been learned — the studio starts blank and the player
// builds the move themselves. Only finishing the lesson unlocks the move.
// The lesson, key poses and pointer are personalised per blueprint. Finishing
// it starts a guided pass that points at the real handles and controls.

struct BlueprintTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    let blueprint: MoveBlueprint
    var onFinish: () -> Void

    @State private var step = 0

    private struct Step {
        let title: String
        let body: String
        var focus: BlueprintFocus? = nil
    }

    private var lesson: BlueprintLesson { BlueprintCoach.lesson(for: blueprint) }

    private var steps: [Step] {
        let move = lesson
        let name = blueprint.name.uppercased()
        return [
            Step(title: "YOU UNLOCKED \(name)",
                 body: "\(blueprint.blurb)\n\nThis is a \(blueprint.technique.label) move. It's yours to animate — but you can't use it in battle until you've built it yourself."),

            Step(title: "HOW \(name) WORKS",
                 body: "Build \(blueprint.name) from these three key frames:\n\n"
                     + move.poses.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"),
                 focus: move.focus),

            Step(title: "POINT: \(move.focus.label)",
                 body: "The arrows show the joint that matters most for \(blueprint.name). After this lesson, the studio will glow the real handle to drag. \(move.tip)",
                 focus: move.focus),

            Step(title: "ADD FRAMES",
                 body: "Tap the film-strip button to key each pose. Your three frames become a sequence that plays from one pose to the next."),

            Step(title: "PLAY & POLISH",
                 body: "Tap the big frame thumbnails to check each pose, then hit play to preview \(blueprint.name). Bigger, cleaner motion means more POWER and more damage."),

            Step(title: "SAVE YOUR MOVE",
                 body: "Your animation saves automatically as YOUR version of \(blueprint.name). Tap SHOW ME to follow the glowing pointers in the studio, then equip it from your Collection."),
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
                .padding(.top, 12)

                Spacer(minLength: 6)

                // Step content.
                VStack(spacing: 8) {
                    Text("\(step + 1) / \(steps.count)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF5C451).opacity(0.7))

                    Text(steps[step].title)
                        .font(DrawnToBattleTypography.display(21))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    if let focus = steps[step].focus {
                        BlueprintPointerDiagram(focus: focus)
                            .scaleEffect(0.5)
                            .frame(height: 124)

                        Text("TARGET: \(focus.label)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0xF5C451))
                    }

                    Text(steps[step].body)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer(minLength: 6)

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
                                .padding(.vertical, 11)
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
                                .padding(.vertical, 11)
                                .background(Capsule().fill(Color(hex: 0xF5C451)))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            onFinish()
                        } label: {
                            Text("SHOW ME IN THE STUDIO")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Capsule().fill(Color(hex: 0xF5C451)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
    }
}
