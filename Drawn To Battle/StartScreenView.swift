import SwiftUI
import UIKit

struct StartScreenView: View {
    let onStart: () -> Void
    @State private var isLoading = false
    @State private var loadingProgress = 0.0

    var body: some View {
        ZStack {
            StartScreenBackground()

            VStack(spacing: 0) {
                Spacer()

                LogoSlot()
                    .frame(maxWidth: 330, maxHeight: 220)
                    .padding(.horizontal, 28)

                Spacer()

                Button {
                    startLoading()
                } label: {
                    Image("DrawnToBattlePlayButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 80)
                        .opacity(isLoading ? 0.4 : 1)
                        .scaleEffect(isLoading ? 0.92 : 1)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Play")
                .padding(.bottom, 24)

                LoadingBar(progress: loadingProgress)
                    .frame(maxWidth: 360)
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 30)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            startLoading()
        }
        .allowsHitTesting(!isLoading)
    }

    private func startLoading() {
        guard !isLoading else { return }
        isLoading = true
        withAnimation(.easeInOut(duration: 0.85)) {
            loadingProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            onStart()
        }
    }
}

private struct LoadingBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.14))
                Capsule()
                    .fill(Color(hex: 0xF5C451))
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 5)
        .accessibilityLabel("Game loading")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

private struct LogoSlot: View {
    var body: some View {
        Group {
            if let logo = UIImage(named: "DrawnToBattleLogo") {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Drawn To Battle")
            } else {
                VStack(spacing: 8) {
                    Text("DRAWN")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                    Text("TO BATTLE")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .tracking(5)
                }
                .foregroundStyle(.white)
                .overlay(alignment: .bottomTrailing) {
                    Text("LOGO")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                        .offset(x: -4, y: 22)
                }
                .accessibilityLabel("Drawn To Battle logo placeholder")
            }
        }
    }
}

private struct StartScreenBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(hex: 0x0C0D12)

                Circle()
                    .fill(Color(hex: 0xF5C451).opacity(0.14))
                    .frame(width: proxy.size.width * 0.95)
                    .blur(radius: 70)
                    .offset(x: proxy.size.width * 0.25, y: -proxy.size.height * 0.3)

                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    .frame(width: proxy.size.width * 0.92)
                    .offset(y: -proxy.size.height * 0.1)

                Canvas { context, size in
                    var path = Path()
                    let baseline = size.height * 0.72
                    path.move(to: CGPoint(x: 0, y: baseline))
                    path.addLine(to: CGPoint(x: size.width, y: baseline - 22))
                    context.stroke(
                        path,
                        with: .color(.white.opacity(0.08)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                    )
                }
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}
