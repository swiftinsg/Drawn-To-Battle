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

        let headCenter = CGPoint(x: cx, y: cy - 120 * scale)
        let headRadius = 25 * scale
        // Shoulders touch the head so there is no floating neck.
        let shoulder = CGPoint(x: cx, y: headCenter.y + headRadius - 2 * scale)
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
        let tint = accessory?.tint ?? Color(hex: 0xF5C451)
        if accessory?.render == .wings {
            drawWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        }

        var torso = Path()
        torso.move(to: shoulder)
        torso.addLine(to: hip)

        var arms = Path()
        // Relaxed arms instead of raised fists.
        arms.move(to: shoulder)
        arms.addLine(to: CGPoint(x: cx - 30 * scale, y: cy - 54 * scale))
        arms.addLine(to: CGPoint(x: cx - 36 * scale, y: cy - 20 * scale))
        arms.move(to: shoulder)
        arms.addLine(to: CGPoint(x: cx + 30 * scale, y: cy - 54 * scale))
        arms.addLine(to: CGPoint(x: cx + 36 * scale, y: cy - 20 * scale))

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

        // Plain head with a dark outline.

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
        switch accessory?.render {
        case .some(.crown):
            drawLeafCrown(in: &context, headCenter: headCenter,
                          headRadius: headRadius, scale: scale, tint: tint)
        case .some(.halo):
            drawHalo(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale, tint: tint)
        case .some(.star):
            drawStar(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale, tint: tint)
        case .some(.wings), nil:
            break
        }
    }

    // MARK: Accessories

    private func drawWings(in context: inout GraphicsContext, cx: CGFloat,
                           cy: CGFloat, scale: CGFloat, tint: Color) {
        let ice = tint
        let blue = tint.opacity(0.7)

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
                let y = cy - CGFloat((108 + index * 18)) * scale
                feather.move(to: CGPoint(x: cx + side * 26 * scale, y: y))
                feather.addLine(
                    to: CGPoint(x: cx + side * CGFloat(88 - index * 8) * scale,
                                y: y - 26 * scale)
                )
                context.stroke(feather, with: .color(ice.opacity(0.65)),
                               style: StrokeStyle(lineWidth: 1.5 * scale))
            }
        }
    }

    private func drawLeafCrown(in context: inout GraphicsContext,
                               headCenter: CGPoint, headRadius: CGFloat,
                               scale: CGFloat, tint: Color) {
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
            context.fill(leaf, with: .color(tint))
            context.stroke(leaf, with: .color(Color.black.opacity(0.45)),
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
            with: .color(tint.opacity(0.85))
        )
    }

    private func drawHalo(in context: inout GraphicsContext,
                          headCenter: CGPoint, headRadius: CGFloat,
                          scale: CGFloat, tint: Color) {
        let center = CGPoint(x: headCenter.x, y: headCenter.y - headRadius - 24 * scale)
        let ring = CGRect(x: center.x - 34 * scale, y: center.y - 9 * scale,
                          width: 68 * scale, height: 18 * scale)

        context.fill(
            Path(ellipseIn: ring.insetBy(dx: -6 * scale, dy: -6 * scale)),
            with: .color(tint.opacity(0.16))
        )
        context.stroke(Path(ellipseIn: ring), with: .color(tint),
                       style: StrokeStyle(lineWidth: 5 * scale))
        context.stroke(Path(ellipseIn: ring), with: .color(Color.white.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 1.5 * scale))
    }

    private func drawStar(in context: inout GraphicsContext,
                          headCenter: CGPoint, headRadius: CGFloat,
                          scale: CGFloat, tint: Color) {
        let center = CGPoint(x: headCenter.x, y: headCenter.y - headRadius - 28 * scale)
        let outer = 22 * scale
        let inner = 9 * scale
        var star = Path()

        for index in 0..<10 {
            let angle = CGFloat(index) * .pi / 5 - .pi / 2
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            if index == 0 { star.move(to: point) } else { star.addLine(to: point) }
        }
        star.closeSubpath()

        context.fill(
            Path(ellipseIn: CGRect(x: center.x - outer * 1.5, y: center.y - outer * 1.5,
                                   width: outer * 3, height: outer * 3)),
            with: .color(tint.opacity(0.14))
        )
        context.fill(star, with: .color(tint))
        context.stroke(star, with: .color(Color.white.opacity(0.9)),
                       style: StrokeStyle(lineWidth: 1.5 * scale))
    }
}
