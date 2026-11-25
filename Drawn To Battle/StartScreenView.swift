import SwiftUI
import UIKit

struct StartScreenView: View {
    let onStart: () -> Void

    private let loadingDuration = 1.4

    @State private var loadingProgress = 0.0
    @State private var canStart = false
    @State private var hasStartedLoading = false
    @State private var promptPulse = false

    var body: some View {
        ZStack {
            StartScreenBackground()

            VStack(spacing: 0) {
                Spacer()

                LogoSlot()
                    .frame(maxWidth: 330, maxHeight: 220)
                    .padding(.horizontal, 28)

                Spacer()

                LoadingBar(progress: loadingProgress)
                    .frame(maxWidth: 360)

                Text("TOUCH TO START")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(promptPulse ? 0.75 : 0.3))
                    .scaleEffect(promptPulse ? 1.06 : 0.96)
                .animation(
                    .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: promptPulse
                )
                .padding(.top, 22)
                .opacity(canStart ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: canStart)
                .accessibilityHidden(!canStart)
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 30)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard canStart else { return }
            onStart()
        }
        .onAppear(perform: startLoading)
    }

    private func startLoading() {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true

        withAnimation(.easeInOut(duration: loadingDuration)) {
            loadingProgress = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration + 0.1) {
            withAnimation(.easeInOut(duration: 0.4)) {
                canStart = true
            }
            promptPulse = true
        }
    }
}

private struct LoadingBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppStyle.hairline)
                Capsule()
                    .fill(AppStyle.gold)
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

struct StartScreenBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppStyle.base

                Circle()
                    .fill(AppStyle.gold.opacity(0.14))
                    .frame(width: proxy.size.width * 0.95)
                    .blur(radius: 70)
                    .offset(x: proxy.size.width * 0.25, y: -proxy.size.height * 0.3)

                Circle()
                    .stroke(AppStyle.softHairline, lineWidth: 1)
                    .frame(width: proxy.size.width * 0.92)
                    .offset(y: -proxy.size.height * 0.1)

                Canvas { context, size in
                    var path = Path()
                    let baseline = size.height * 0.72
                    path.move(to: CGPoint(x: 0, y: baseline))
                    path.addLine(to: CGPoint(x: size.width, y: baseline - 22))
                    context.stroke(
                        path,
                        with: .color(AppStyle.softHairline),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 8])
                    )
                }
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}
