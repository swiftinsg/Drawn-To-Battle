import SwiftUI
import RiveRuntime

/// Plays the ambient `HomeBackground.riv` scene behind the home hub.
///
/// The Rive view is transparent, so the existing SwiftUI backdrop stays
/// visible underneath. If the asset ever fails to load, the backdrop alone
/// keeps the home screen looking exactly as before.
struct RiveHomeBackground<Fallback: View>: View {
    @ViewBuilder var fallback: () -> Fallback

    var body: some View {
        ZStack {
            fallback()

            AsyncRiveUIViewRepresentable {
                let worker = try await Worker(configuration: .init())
                let file = try await File(source: .local("HomeBackground", Bundle.main), worker: worker)
                return try await Rive(file: file, fit: .cover(alignment: .center))
            }
            .frameRate(.fps(30))
            .opacity(0.9)
            .allowsHitTesting(false)
        }
    }
}
