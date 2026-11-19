import SwiftUI

// MARK: - Home fighter

/// The hero figure shown in the middle of the hub. It stays a hand-drawn
/// stickman, but with a bold outline and any unlocked world accessory.
struct FighterFigureView: View {
    let accessory: Accessory?

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                draw(in: &context, size: size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let scale = min(size.width / 220, size.height / 350)
        guard scale > 0 else { return }

        let cx = size.width / 2
        let cy = size.height * 0.50

        let gold = Color(hex: 0xF5C451)
        let outlineColor = Color.black.opacity(0.72)
        let ink = Color.white.opacity(0.96)

        let headCenter = CGPoint(x: cx, y: cy - 122 * scale)
        let headRadius = 25 * scale
        let shoulder = CGPoint(x: cx, y: cy - 86 * scale)
        let hip = CGPoint(x: cx, y: cy + 20 * scale)

        // Spawn ring and shadow under the fighter.
        context.fill(
            Path(ellipseIn: CGRect(x: cx - 72 * scale, y: cy + 116 * scale,
                                   width: 144 * scale, height: 18 * scale)),
            with: .color(Color.black.opacity(0.5))
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: cx - 82 * scale, y: cy + 108 * scale,
                                   width: 164 * scale, height: 30 * scale)),
            with: .color(gold.opacity(0.55)),
            style: StrokeStyle(lineWidth: 2 * scale)
        )

        // Wings sit behind the body.
        if accessory == .iceWings {
            drawWings(in: &context, cx: cx, cy: cy, scale: scale)
        }

        var torso = Path()
        torso.move(to: shoulder)
        torso.addLine(to: hip)

        var arms = Path()
        let leftFist = CGPoint(x: cx - 58 * scale, y: cy - 98 * scale)
        let rightFist = CGPoint(x: cx + 62 * scale, y: cy - 106 * scale)
        arms.move(to: CGPoint(x: cx, y: cy - 76 * scale))
        arms.addLine(to: CGPoint(x: cx - 40 * scale, y: cy - 62 * scale))
        arms.addLine(to: leftFist)
        arms.move(to: CGPoint(x: cx, y: cy - 76 * scale))
        arms.addLine(to: CGPoint(x: cx + 42 * scale, y: cy - 70 * scale))
        arms.addLine(to: rightFist)

        var legs = Path()
        legs.move(to: hip)
        legs.addLine(to: CGPoint(x: cx - 28 * scale, y: cy + 78 * scale))
        legs.addLine(to: CGPoint(x: cx - 34 * scale, y: cy + 110 * scale))
        legs.move(to: hip)
        legs.addLine(to: CGPoint(x: cx + 28 * scale, y: cy + 78 * scale))
        legs.addLine(to: CGPoint(x: cx + 34 * scale, y: cy + 110 * scale))

        let outline = StrokeStyle(lineWidth: 15 * scale, lineCap: .round, lineJoin: .round)
        let inner = StrokeStyle(lineWidth: 9 * scale, lineCap: .round, lineJoin: .round)
        for path in [torso, arms, legs] {
            context.stroke(path, with: .color(outlineColor), style: outline)
            context.stroke(path, with: .color(ink), style: inner)
        }

        // Gold fists give the silhouette a bit of character.
        for fist in [leftFist, rightFist] {
            context.fill(
                Path(ellipseIn: CGRect(x: fist.x - 7 * scale, y: fist.y - 7 * scale,
                                       width: 14 * scale, height: 14 * scale)),
                with: .color(gold)
            )
        }

        // Head with a dark outline and two eyes.
        let outerR = headRadius + 3 * scale
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x - outerR, y: headCenter.y - outerR,
                                   width: outerR * 2, height: outerR * 2)),
            with: .color(outlineColor)
        )
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius,
                                   width: headRadius * 2, height: headRadius * 2)),
            with: .color(ink)
        )
        let eye = Color(hex: 0x11131A)
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x - 10 * scale, y: headCenter.y - 4 * scale,
                                   width: 5 * scale, height: 7 * scale)),
            with: .color(eye)
        )
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x + 5 * scale, y: headCenter.y - 4 * scale,
                                   width: 5 * scale, height: 7 * scale)),
            with: .color(eye)
        )

        switch accessory {
        case .some(.leafCrown):
            drawLeafCrown(in: &context, headCenter: headCenter,
                          headRadius: headRadius, scale: scale)
        case .some(.solarHalo):
            drawHalo(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale)
        case .some(.iceWings), nil:
            break
        }
    }

    // MARK: Accessories

    private func drawWings(in context: inout GraphicsContext, cx: CGFloat,
                           cy: CGFloat, scale: CGFloat) {
        let ice = Color(hex: 0xB3E5FC)
        let blue = Color(hex: 0x4FC3F7)

        for side in [CGFloat(-1), CGFloat(1)] {
            let root = CGPoint(x: cx + side * 16 * scale, y: cy - 72 * scale)
            var wing = Path()
            wing.move(to: root)
            wing.addQuadCurve(
                to: CGPoint(x: cx + side * 112 * scale, y: cy - 166 * scale),
                control: CGPoint(x: cx + side * 66 * scale, y: cy - 156 * scale)
            )
            wing.addQuadCurve(
                to: CGPoint(x: cx + side * 98 * scale, y: cy - 92 * scale),
                control: CGPoint(x: cx + side * 124 * scale, y: cy - 120 * scale)
            )
            wing.addQuadCurve(
                to: root,
                control: CGPoint(x: cx + side * 52 * scale, y: cy - 58 * scale)
            )
            context.fill(wing, with: .color(blue.opacity(0.42)))
            context.stroke(wing, with: .color(ice.opacity(0.95)),
                           style: StrokeStyle(lineWidth: 2 * scale))

            for index in 0..<3 {
                var feather = Path()
                let y = cy - (108 + index * 18) * scale
                feather.move(to: CGPoint(x: cx + side * 26 * scale, y: y))
                feather.addLine(
                    to: CGPoint(x: cx + side * (88 - index * 8) * scale,
                                y: y - 26 * scale)
                )
                context.stroke(feather, with: .color(ice.opacity(0.65)),
                               style: StrokeStyle(lineWidth: 1.5 * scale))
            }
        }
    }

    private func drawLeafCrown(in context: inout GraphicsContext,
                               headCenter: CGPoint, headRadius: CGFloat, scale: CGFloat) {
        let baseY = headCenter.y - headRadius + 5 * scale
        let angles: [CGFloat] = [-0.95, -0.48, 0, 0.48, 0.95]

        for (index, angle) in angles.enumerated() {
            let base = CGPoint(
                x: headCenter.x + sin(angle) * headRadius * 0.7,
                y: baseY + (1 - cos(angle)) * 4 * scale
            )
            let length = (index == 2 ? 36 : 27) * scale
            let tip = CGPoint(
                x: base.x + sin(angle) * length,
                y: base.y - cos(angle) * length
            )
            let perpendicular = CGPoint(x: cos(angle), y: sin(angle))
            let mid = CGPoint(x: (base.x + tip.x) / 2, y: (base.y + tip.y) / 2)
            let width = 8 * scale

            var leaf = Path()
            leaf.move(to: base)
            leaf.addQuadCurve(
                to: tip,
                control: CGPoint(x: mid.x + perpendicular.x * width,
                                 y: mid.y + perpendicular.y * width)
            )
            leaf.addQuadCurve(
                to: base,
                control: CGPoint(x: mid.x - perpendicular.x * width,
                                 y: mid.y - perpendicular.y * width)
            )
            context.fill(leaf, with: .color(Color(hex: index == 2 ? 0x6DD36D : 0x3FA65C)))
            context.stroke(leaf, with: .color(Color(hex: 0x247A3C)),
                           style: StrokeStyle(lineWidth: 1.2 * scale))

            var vein = Path()
            vein.move(to: base)
            vein.addLine(to: tip)
            context.stroke(vein, with: .color(Color.white.opacity(0.45)),
                           style: StrokeStyle(lineWidth: scale))
        }

        // Band holding the leaves in place.
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x - headRadius, y: baseY - 3 * scale,
                                   width: headRadius * 2, height: 9 * scale)),
            with: .color(Color(hex: 0x247A3C))
        )
    }

    private func drawHalo(in context: inout GraphicsContext,
                          headCenter: CGPoint, headRadius: CGFloat, scale: CGFloat) {
        let center = CGPoint(x: headCenter.x, y: headCenter.y - headRadius - 24 * scale)
        let ring = CGRect(x: center.x - 34 * scale, y: center.y - 9 * scale,
                          width: 68 * scale, height: 18 * scale)
        let gold = Color(hex: 0xF5C451)

        context.fill(
            Path(ellipseIn: ring.insetBy(dx: -6 * scale, dy: -6 * scale)),
            with: .color(gold.opacity(0.16))
        )
        context.stroke(Path(ellipseIn: ring), with: .color(gold),
                       style: StrokeStyle(lineWidth: 5 * scale))
        context.stroke(Path(ellipseIn: ring), with: .color(Color.white.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 1.5 * scale))
    }
}
