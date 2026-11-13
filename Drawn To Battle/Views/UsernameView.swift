import SwiftUI

// MARK: - First-launch fighter naming

/// Shown once, before the hub, when the fighter has no name yet.
struct UsernameView: View {
    @ObservedObject var game: GameSave
    var onDone: () -> Void

    @State private var name = ""
    @FocusState private var fieldFocused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                StartScreenBackground()

                // Scrolls out of the keyboard's way in tight orientations.
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        Text("NAME YOUR FIGHTER")
                            .font(DrawnToBattleTypography.display(26))
                            .foregroundStyle(.white)

                        Text("This is the name the galaxy will remember.")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 8)

                        TextField("FIGHTER NAME", text: $name)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .focused($fieldFocused)
                            .submitLabel(.done)
                            .onSubmit(confirm)
                            .onChange(of: name) { _, newValue in
                                if newValue.count > 14 { name = String(newValue.prefix(14)) }
                            }
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(hex: 0xF5C451).opacity(0.35), lineWidth: 1.5)
                            )
                            .padding(.horizontal, 34)
                            .padding(.top, 26)

                        Button {
                            confirm()
                        } label: {
                            Text("ENTER THE ARENA")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(.black)
                                .frame(maxWidth: 240)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule().fill(trimmed.isEmpty ? Color.white.opacity(0.15) : Color(hex: 0xF5C451))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(trimmed.isEmpty)
                        .padding(.top, 22)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                fieldFocused = true
            }
        }
    }

    private func confirm() {
        guard !trimmed.isEmpty else { return }
        fieldFocused = false
        game.username = trimmed
        onDone()
    }
}
