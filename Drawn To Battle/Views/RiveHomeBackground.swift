import SwiftUI
import RiveRuntime

/// Plays the ambient `HomeBackground.riv` scene behind the home hub.
/// The hub's dark base color sits behind it, so no static backdrop is needed.
struct RiveHomeBackground: View {
    var body: some View {
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
