import SwiftUI

/// Universally readable capsule machine, shared by the gacha page and the
/// home-screen gacha button.
struct GachaMachineIcon: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 80, size.height / 80)
            guard scale > 0 else { return }
            context.translateBy(x: (size.width - 80 * scale) / 2, y: (size.height - 80 * scale) / 2)
            context.scaleBy(x: scale, y: scale)

            let gold = Color(hex: 0xF5C451)
            let ink = Color(hex: 0x11131A)
            let blue = Color(hex: 0x4FC3F7)

            // Machine body.
            let body = Path(roundedRect: CGRect(x: 16, y: 26, width: 48, height: 46), cornerRadius: 12)
            context.fill(body, with: .color(Color(hex: 0x14161E)))
            context.stroke(body, with: .color(gold.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 2.5))

            // Glass dome with capsules.
            let dome = Path(ellipseIn: CGRect(x: 24, y: 8, width: 32, height: 32))
            context.fill(dome, with: .color(blue.opacity(0.3)))
            context.stroke(dome, with: .color(blue.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 2))

            let capsules: [(CGFloat, CGFloat, CGFloat, Color)] = [
                (33, 21, 6, gold),
                (46, 20, 5, Color(hex: 0xA86CFF)),
                (40, 29, 5, Color(hex: 0xE86A6A)),
            ]
            for capsule in capsules {
                let x = capsule.0 - capsule.2
                let y = capsule.1 - capsule.2
                let diameter = capsule.2 * 2
                context.fill(Path(ellipseIn: CGRect(x: x, y: y,
                                                     width: diameter, height: diameter)),
                             with: .color(capsule.3))
                context.fill(Path(ellipseIn: CGRect(x: x + diameter * 0.22,
                                                     y: y + diameter * 0.18,
                                                     width: diameter * 0.22,
                                                     height: diameter * 0.22)),
                             with: .color(.white.opacity(0.8)))
            }

            // Knob and chute.
            let knob = Path(ellipseIn: CGRect(x: 35, y: 43, width: 10, height: 10))
            context.fill(knob, with: .color(gold))
            context.stroke(knob, with: .color(ink.opacity(0.5)),
                           style: StrokeStyle(lineWidth: 1.5))

            let slot = Path(roundedRect: CGRect(x: 29, y: 57, width: 22, height: 9), cornerRadius: 4)
            context.fill(slot, with: .color(ink))
            context.stroke(slot, with: .color(gold.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1.5))

            // Capsule waiting in the chute and the base plate.
            context.fill(Path(ellipseIn: CGRect(x: 35, y: 57, width: 10, height: 10)), with: .color(gold))
            let plate = Path(roundedRect: CGRect(x: 14, y: 68, width: 52, height: 6), cornerRadius: 3)
            context.fill(plate, with: .color(gold))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
