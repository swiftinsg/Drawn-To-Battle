import SwiftUI

// MARK: - Home fighter

/// The hero figure shown in the middle of the hub. It stays a hand-drawn
/// stickman, but with a bold outline and any unlocked world cosmetic.
struct FighterFigureView: View {
    let accessory: Accessory?

    private enum OrbitStyle {
        case pebble
        case water
        case fire
        case soul
    }

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
        // Extra headroom keeps tall headgear, halos and butterflies on screen,
        // and the whole fighter sits lower so cosmetics never clip the top.
        let scale = min(size.width / 220, size.height / 400)
        guard scale > 0 else { return }

        let cx = size.width / 2
        let cy = size.height * 0.56

        let gold = Color(hex: 0xF5C451)
        let outlineColor = Color.black.opacity(0.72)
        let ink = Color.white.opacity(0.96)

        let headCenter = CGPoint(x: cx, y: cy - 118 * scale)
        let headRadius = 24 * scale
        // A calm A stance: head, shoulders and hips line up, limbs hang low.
        let shoulder = CGPoint(x: cx, y: headCenter.y + headRadius + 5 * scale)
        let hip = CGPoint(x: cx, y: cy + 18 * scale)

        let shoulderL = CGPoint(x: cx - 7 * scale, y: shoulder.y + 3 * scale)
        let elbowL = CGPoint(x: cx - 24 * scale, y: cy - 50 * scale)
        let handL = CGPoint(x: cx - 28 * scale, y: cy - 14 * scale)
        let shoulderR = CGPoint(x: cx + 7 * scale, y: shoulder.y + 3 * scale)
        let elbowR = CGPoint(x: cx + 24 * scale, y: cy - 50 * scale)
        let handR = CGPoint(x: cx + 28 * scale, y: cy - 14 * scale)

        let hipL = CGPoint(x: cx - 3 * scale, y: hip.y)
        let kneeL = CGPoint(x: cx - 16 * scale, y: cy + 64 * scale)
        let footL = CGPoint(x: cx - 20 * scale, y: cy + 104 * scale)
        let hipR = CGPoint(x: cx + 3 * scale, y: hip.y)
        let kneeR = CGPoint(x: cx + 16 * scale, y: cy + 64 * scale)
        let footR = CGPoint(x: cx + 20 * scale, y: cy + 104 * scale)

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

        let tint = accessory?.tint ?? gold
        let render = accessory?.render

        // Back cosmetics sit behind the body and head.
        if render == .wings {
            drawWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        }
        if render == .fairyWings {
            drawFairyWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        }
        if render == .fireWings {
            drawFireWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        }
        if render == .fireHalo {
            drawFireHalo(in: &context, headCenter: headCenter,
                         headRadius: headRadius, scale: scale, tint: tint)
        }
        if render == .sunRing {
            drawSunRing(in: &context, headCenter: headCenter,
                        headRadius: headRadius, scale: scale, tint: tint)
        }
        if render == .orbit {
            drawOrbit(in: &context, cx: cx, cy: cy, scale: scale,
                      tint: tint, style: accessory == .tideOrbit ? .water : .pebble)
        }
        if render == .fireOrbit {
            drawOrbit(in: &context, cx: cx, cy: cy, scale: scale,
                      tint: tint, style: .fire)
        }
        if render == .soulOrbit {
            drawOrbit(in: &context, cx: cx, cy: cy, scale: scale,
                      tint: tint, style: .soul)
        }

        // Just a hair of separation at elbows and knees keeps the hand drawn
        // look without making the body feel broken apart.
        let joint = 1.5 * scale
        var torso = Path()
        addSegment(&torso, from: shoulder, to: hip, trimStart: 0, trimEnd: 0)

        var arms = Path()
        for (start, elbow, hand) in [
            (shoulderL, elbowL, handL), (shoulderR, elbowR, handR)
        ] {
            addSegment(&arms, from: start, to: elbow, trimStart: 0, trimEnd: joint)
            addSegment(&arms, from: elbow, to: hand, trimStart: joint, trimEnd: 0)
        }

        var legs = Path()
        for (start, knee, foot) in [
            (hipL, kneeL, footL), (hipR, kneeR, footR)
        ] {
            addSegment(&legs, from: start, to: knee, trimStart: 0, trimEnd: joint)
            addSegment(&legs, from: knee, to: foot, trimStart: joint, trimEnd: 0)
        }

        let outline = StrokeStyle(lineWidth: 12.5 * scale, lineCap: .round, lineJoin: .round)
        let inner = StrokeStyle(lineWidth: 8 * scale, lineCap: .round, lineJoin: .round)
        for path in [torso, arms, legs] {
            context.stroke(path, with: .color(outlineColor), style: outline)
            context.stroke(path, with: .color(ink), style: inner)
        }

        // Plain head with a dark outline.
        let outerR = headRadius + 2.5 * scale
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

        // Front cosmetics.
        switch render {
        case .some(.crown):
            drawLeafCrown(in: &context, headCenter: headCenter,
                          headRadius: headRadius, scale: scale, tint: tint)
        case .some(.halo):
            drawHalo(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale, tint: tint)
        case .some(.star):
            drawStar(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale, tint: tint)
        case .some(.butterflies):
            drawButterflies(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        case .some(.leaves):
            drawLeaves(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        case .some(.crystalCrown):
            drawCrystalCrown(in: &context, headCenter: headCenter,
                             headRadius: headRadius, scale: scale, tint: tint)
        case .some(.flowerCrown):
            drawFlowerCrown(in: &context, headCenter: headCenter,
                            headRadius: headRadius, scale: scale, tint: tint)
        case .some(.wings), .some(.orbit), .some(.fireOrbit), .some(.soulOrbit),
             .some(.fairyWings), .some(.fireWings), .some(.fireHalo),
             .some(.sunRing), nil:
            break
        }
    }

    /// Draws a line with tiny trims at each end so joints look separate.
    private func addSegment(_ path: inout Path, from a: CGPoint, to b: CGPoint,
                            trimStart: CGFloat, trimEnd: CGFloat) {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let length = hypot(dx, dy)
        guard length > 0.01 else { return }
        let ux = dx / length
        let uy = dy / length
        let start = CGPoint(x: a.x + ux * trimStart, y: a.y + uy * trimStart)
        let end = CGPoint(x: b.x - ux * trimEnd, y: b.y - uy * trimEnd)
        path.move(to: start)
        path.addLine(to: end)
    }

    // MARK: Cosmetics

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

    private func drawOrbit(in context: inout GraphicsContext, cx: CGFloat,
                           cy: CGFloat, scale: CGFloat, tint: Color,
                           style: OrbitStyle) {
        // Soul fire has five flames with the bottom slot left empty.
        let positions = style == .soul ? [0, 1, 2, 4, 5] : [0, 1, 2, 3, 4]
        let divisor: CGFloat = style == .soul ? 6 : 5
        for index in positions {
            let angle = CGFloat(index) / divisor * 2 * .pi - .pi / 2
            let center = CGPoint(x: cx + cos(angle) * 70 * scale,
                                 y: cy - 34 * scale + sin(angle) * 78 * scale)
            let r = (style == .water ? 7 : 6) * scale

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r * 2, y: center.y - r * 2,
                                       width: r * 4, height: r * 4)),
                with: .color(tint.opacity(0.18))
            )

            switch style {
            case .water:
                var drop = Path()
                drop.move(to: CGPoint(x: center.x, y: center.y - r * 1.7))
                drop.addQuadCurve(
                    to: CGPoint(x: center.x - r, y: center.y + r * 0.6),
                    control: CGPoint(x: center.x - r, y: center.y - r * 0.5)
                )
                drop.addQuadCurve(
                    to: CGPoint(x: center.x + r, y: center.y + r * 0.6),
                    control: CGPoint(x: center.x + r, y: center.y - r * 0.5)
                )
                drop.addQuadCurve(
                    to: CGPoint(x: center.x, y: center.y - r * 1.7),
                    control: CGPoint(x: center.x, y: center.y + r * 1.4)
                )
                context.fill(drop, with: .color(tint.opacity(0.9)))
            case .fire:
                drawFlame(in: &context, center: center, radius: r,
                          color: tint, core: Color(hex: 0xFFE08A))
            case .soul:
                drawFlame(in: &context, center: center, radius: r,
                          color: tint, core: Color(hex: 0x9FF6FF))
            case .pebble:
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r,
                                           width: r * 2, height: r * 2)),
                    with: .color(tint.opacity(0.9))
                )
            }

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r * 0.4, y: center.y - r * 0.5,
                                       width: r * 0.55, height: r * 0.55)),
                with: .color(Color.white.opacity(0.75))
            )
        }
    }

    private func drawFlame(in context: inout GraphicsContext, center: CGPoint,
                           radius: CGFloat, color: Color, core: Color) {
        var flame = Path()
        flame.move(to: CGPoint(x: center.x, y: center.y - radius * 1.9))
        flame.addQuadCurve(
            to: CGPoint(x: center.x + radius, y: center.y + radius * 0.7),
            control: CGPoint(x: center.x + radius * 1.25, y: center.y - radius * 0.35)
        )
        flame.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + radius * 1.25),
            control: CGPoint(x: center.x + radius * 0.35, y: center.y + radius * 1.15)
        )
        flame.addQuadCurve(
            to: CGPoint(x: center.x - radius, y: center.y + radius * 0.7),
            control: CGPoint(x: center.x - radius * 0.35, y: center.y + radius * 1.15)
        )
        flame.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - radius * 1.9),
            control: CGPoint(x: center.x - radius * 1.25, y: center.y - radius * 0.35)
        )
        context.fill(flame, with: .color(color.opacity(0.95)))
        context.stroke(flame, with: .color(Color.white.opacity(0.55)),
                       style: StrokeStyle(lineWidth: max(0.6, radius * 0.12)))

        var inner = Path()
        inner.move(to: CGPoint(x: center.x, y: center.y - radius * 0.9))
        inner.addQuadCurve(
            to: CGPoint(x: center.x + radius * 0.45, y: center.y + radius * 0.5),
            control: CGPoint(x: center.x + radius * 0.65, y: center.y)
        )
        inner.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + radius * 0.85),
            control: CGPoint(x: center.x + radius * 0.2, y: center.y + radius * 0.8)
        )
        inner.addQuadCurve(
            to: CGPoint(x: center.x - radius * 0.45, y: center.y + radius * 0.5),
            control: CGPoint(x: center.x - radius * 0.2, y: center.y + radius * 0.8)
        )
        inner.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - radius * 0.9),
            control: CGPoint(x: center.x - radius * 0.65, y: center.y)
        )
        context.fill(inner, with: .color(core.opacity(0.9)))
    }

    private func drawButterflies(in context: inout GraphicsContext, cx: CGFloat,
                                 cy: CGFloat, scale: CGFloat, tint: Color) {
        let spots: [(CGFloat, CGFloat, CGFloat)] = [
            (-62, -134, 1.05), (58, -120, 0.9), (-50, -72, 0.72), (68, -52, 0.6)
        ]
        for (dx, dy, factor) in spots {
            let center = CGPoint(x: cx + dx * scale, y: cy + dy * scale)
            let r = 7 * scale * factor

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r * 2.2, y: center.y - r * 2.2,
                                       width: r * 4.4, height: r * 4.4)),
                with: .color(tint.opacity(0.16))
            )

            for side in [CGFloat(-1), CGFloat(1)] {
                var wing = Path()
                wing.move(to: center)
                wing.addQuadCurve(
                    to: CGPoint(x: center.x + side * r * 2, y: center.y - r * 1.7),
                    control: CGPoint(x: center.x + side * r * 1.6, y: center.y - r * 2.4)
                )
                wing.addQuadCurve(
                    to: center,
                    control: CGPoint(x: center.x + side * r * 2.1, y: center.y + r * 0.3)
                )
                context.fill(wing, with: .color(tint.opacity(0.88)))
                context.stroke(wing, with: .color(Color.white.opacity(0.8)),
                               style: StrokeStyle(lineWidth: max(0.6, scale)))
            }

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r * 0.3, y: center.y - r * 1.1,
                                       width: r * 0.6, height: r * 2.2)),
                with: .color(Color(hex: 0x2E3B2A))
            )
        }
    }

    private func drawLeaves(in context: inout GraphicsContext, cx: CGFloat,
                            cy: CGFloat, scale: CGFloat, tint: Color) {
        let spots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-72, -142, -0.5, 0.95), (66, -130, 0.6, 0.85),
            (-76, -62, 0.8, 0.72), (74, -40, -0.7, 0.65), (2, -182, 0.15, 0.6)
        ]
        for (dx, dy, angle, factor) in spots {
            let center = CGPoint(x: cx + dx * scale, y: cy + dy * scale)
            let length = 18 * scale * factor
            let width = 8 * scale * factor
            let direction = CGPoint(x: sin(angle), y: -cos(angle))
            let perpendicular = CGPoint(x: cos(angle), y: sin(angle))
            let base = CGPoint(x: center.x - direction.x * length / 2,
                               y: center.y - direction.y * length / 2)
            let tip = CGPoint(x: center.x + direction.x * length / 2,
                              y: center.y + direction.y * length / 2)

            var leaf = Path()
            leaf.move(to: base)
            leaf.addQuadCurve(
                to: tip,
                control: CGPoint(x: center.x + perpendicular.x * width,
                                 y: center.y + perpendicular.y * width)
            )
            leaf.addQuadCurve(
                to: base,
                control: CGPoint(x: center.x - perpendicular.x * width,
                                 y: center.y - perpendicular.y * width)
            )
            context.fill(leaf, with: .color(tint.opacity(0.92)))
            context.stroke(leaf, with: .color(Color.white.opacity(0.7)),
                           style: StrokeStyle(lineWidth: max(0.6, scale)))
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

    private func drawFairyWings(in context: inout GraphicsContext, cx: CGFloat,
                                cy: CGFloat, scale: CGFloat, tint: Color) {
        for side in [CGFloat(-1), CGFloat(1)] {
            let root = CGPoint(x: cx + side * 12 * scale, y: cy - 72 * scale)
            for factor in [CGFloat(1), CGFloat(0.72)] {
                var wing = Path()
                wing.move(to: root)
                wing.addQuadCurve(
                    to: CGPoint(x: cx + side * 92 * scale * factor,
                                y: cy - 152 * scale * factor),
                    control: CGPoint(x: cx + side * 62 * scale * factor,
                                     y: cy - 160 * scale * factor)
                )
                wing.addQuadCurve(
                    to: root,
                    control: CGPoint(x: cx + side * 104 * scale * factor,
                                     y: cy - 82 * scale * factor)
                )
                context.fill(wing, with: .color(tint.opacity(factor == 1 ? 0.32 : 0.2)))
                context.stroke(wing, with: .color(tint.opacity(0.9)),
                               style: StrokeStyle(lineWidth: 1.6 * scale))
            }

            for index in 0..<3 {
                let dot = CGPoint(x: cx + side * CGFloat(58 + index * 16) * scale,
                                  y: cy - CGFloat(138 - index * 22) * scale)
                context.fill(
                    Path(ellipseIn: CGRect(x: dot.x - 2.5 * scale,
                                           y: dot.y - 2.5 * scale,
                                           width: 5 * scale, height: 5 * scale)),
                    with: .color(Color.white.opacity(0.9))
                )
            }
        }
    }

    private func drawFireWings(in context: inout GraphicsContext, cx: CGFloat,
                               cy: CGFloat, scale: CGFloat, tint: Color) {
        for side in [CGFloat(-1), CGFloat(1)] {
            let root = CGPoint(x: cx + side * 14 * scale, y: cy - 74 * scale)
            var wing = Path()
            wing.move(to: root)
            wing.addQuadCurve(
                to: CGPoint(x: cx + side * 118 * scale, y: cy - 168 * scale),
                control: CGPoint(x: cx + side * 70 * scale, y: cy - 160 * scale)
            )
            wing.addLine(to: CGPoint(x: cx + side * 100 * scale, y: cy - 132 * scale))
            wing.addLine(to: CGPoint(x: cx + side * 126 * scale, y: cy - 118 * scale))
            wing.addLine(to: CGPoint(x: cx + side * 92 * scale, y: cy - 96 * scale))
            wing.addQuadCurve(
                to: root,
                control: CGPoint(x: cx + side * 48 * scale, y: cy - 58 * scale)
            )
            context.fill(wing, with: .color(tint.opacity(0.42)))
            context.stroke(wing, with: .color(tint.opacity(0.95)),
                           style: StrokeStyle(lineWidth: 2 * scale))

            for index in 0..<3 {
                let tip = CGPoint(x: cx + side * CGFloat(60 + index * 20) * scale,
                                  y: cy - CGFloat(150 - index * 16) * scale)
                drawFlame(in: &context, center: tip, radius: 7 * scale,
                          color: tint, core: Color(hex: 0xFFE08A))
            }
        }
    }

    private func drawFireHalo(in context: inout GraphicsContext,
                              headCenter: CGPoint, headRadius: CGFloat,
                              scale: CGFloat, tint: Color) {
        let center = CGPoint(x: headCenter.x, y: headCenter.y - headRadius - 12 * scale)
        let radiusX = headRadius + 30 * scale
        let radiusY = headRadius * 0.55 + 10 * scale
        let glowX = radiusX + 8 * scale
        let glowY = radiusY + 8 * scale

        context.fill(
            Path(ellipseIn: CGRect(x: center.x - glowX, y: center.y - glowY,
                                   width: glowX * 2, height: glowY * 2)),
            with: .color(tint.opacity(0.12))
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - radiusX, y: center.y - radiusY,
                                   width: radiusX * 2, height: radiusY * 2)),
            with: .color(tint.opacity(0.8)),
            style: StrokeStyle(lineWidth: 3 * scale)
        )

        for index in 0..<12 {
            let angle = CGFloat(index) / 12 * 2 * .pi
            let point = CGPoint(x: center.x + cos(angle) * radiusX,
                                y: center.y + sin(angle) * radiusY)
            drawFlame(in: &context, center: point, radius: 6 * scale,
                      color: tint, core: Color(hex: 0xFFE08A))
        }
    }

    private func drawSunRing(in context: inout GraphicsContext,
                             headCenter: CGPoint, headRadius: CGFloat,
                             scale: CGFloat, tint: Color) {
        let radius = headRadius + 26 * scale
        let glow = radius + 10 * scale

        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x - glow, y: headCenter.y - glow,
                                   width: glow * 2, height: glow * 2)),
            with: .color(tint.opacity(0.12))
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: headCenter.x - radius, y: headCenter.y - radius,
                                   width: radius * 2, height: radius * 2)),
            with: .color(tint.opacity(0.85)),
            style: StrokeStyle(lineWidth: 5 * scale)
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: headCenter.x - radius, y: headCenter.y - radius,
                                   width: radius * 2, height: radius * 2)),
            with: .color(Color.white.opacity(0.85)),
            style: StrokeStyle(lineWidth: 1.5 * scale)
        )

        for index in 0..<16 {
            let angle = CGFloat(index) / 16 * 2 * .pi
            let inner = radius + 6 * scale
            let outer = radius + (index.isMultiple(of: 2) ? 20 : 13) * scale
            var ray = Path()
            ray.move(to: CGPoint(x: headCenter.x + cos(angle) * inner,
                                 y: headCenter.y + sin(angle) * inner))
            ray.addLine(to: CGPoint(x: headCenter.x + cos(angle) * outer,
                                    y: headCenter.y + sin(angle) * outer))
            context.stroke(ray, with: .color(tint.opacity(0.8)),
                           style: StrokeStyle(lineWidth: 2 * scale))
        }
    }

    private func drawCrystalCrown(in context: inout GraphicsContext,
                                  headCenter: CGPoint, headRadius: CGFloat,
                                  scale: CGFloat, tint: Color) {
        let baseY = headCenter.y - headRadius + 3 * scale
        let spikes: [(CGFloat, CGFloat)] = [
            (-0.85, 24), (-0.42, 34), (0, 42), (0.42, 34), (0.85, 24)
        ]

        for (angle, length) in spikes {
            let base = CGPoint(x: headCenter.x + sin(angle) * headRadius * 0.72,
                               y: baseY + (1 - cos(angle)) * 3 * scale)
            let tip = CGPoint(x: base.x + sin(angle) * length * scale,
                              y: base.y - cos(angle) * length * scale)
            let half = 6 * scale

            var crystal = Path()
            crystal.move(to: base)
            crystal.addLine(to: CGPoint(x: tip.x - half * 0.5, y: tip.y + half))
            crystal.addLine(to: tip)
            crystal.addLine(to: CGPoint(x: tip.x + half * 0.5, y: tip.y + half))
            crystal.addLine(to: base)
            context.fill(crystal, with: .color(tint.opacity(0.85)))
            context.stroke(crystal, with: .color(Color.white.opacity(0.85)),
                           style: StrokeStyle(lineWidth: 1.2 * scale))

            var shine = Path()
            shine.move(to: base)
            shine.addLine(to: tip)
            context.stroke(shine, with: .color(Color.white.opacity(0.5)),
                           style: StrokeStyle(lineWidth: scale))
        }

        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x - headRadius, y: baseY - 3 * scale,
                                   width: headRadius * 2, height: 8 * scale)),
            with: .color(tint.opacity(0.75))
        )
    }

    private func drawFlowerCrown(in context: inout GraphicsContext,
                                 headCenter: CGPoint, headRadius: CGFloat,
                                 scale: CGFloat, tint: Color) {
        let spots: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.9, 0.05, 0.85), (-0.45, -0.35, 1), (0, -0.55, 1.1),
            (0.45, -0.35, 1), (0.9, 0.05, 0.85)
        ]

        for (dx, dy, factor) in spots {
            let center = CGPoint(x: headCenter.x + dx * headRadius * 1.05,
                                 y: headCenter.y - headRadius + dy * headRadius * 0.8)
            let r = 7 * scale * factor

            for petal in 0..<5 {
                let angle = CGFloat(petal) / 5 * 2 * .pi - .pi / 2
                let petalCenter = CGPoint(x: center.x + cos(angle) * r,
                                          y: center.y + sin(angle) * r)
                context.fill(
                    Path(ellipseIn: CGRect(x: petalCenter.x - r * 0.6,
                                           y: petalCenter.y - r * 0.6,
                                           width: r * 1.2, height: r * 1.2)),
                    with: .color(tint.opacity(0.9))
                )
            }

            context.fill(
                Path(ellipseIn: CGRect(x: center.x - r * 0.45,
                                       y: center.y - r * 0.45,
                                       width: r * 0.9, height: r * 0.9)),
                with: .color(Color(hex: 0xFFD54F))
            )
        }
    }

    // MARK: Battle overlay

    enum BattleLayer {
        case back
        case front
    }

    /// Draws only the equipped cosmetic around a battle stickman. The battle
    /// figure keeps its own pose; this reuses the hub art at the head's scale.
    func drawBattleLayer(_ layer: BattleLayer, in context: inout GraphicsContext,
                         headCenter: CGPoint, headRadius: CGFloat, hip: CGPoint) {
        guard let accessory else { return }
        let scale = max(0.28, headRadius / 24)
        let cx = hip.x
        let cy = hip.y - 18 * scale
        let tint = accessory.tint
        let render = accessory.render

        if layer == .back {
            if render == .wings {
                drawWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
            }
            if render == .fairyWings {
                drawFairyWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
            }
            if render == .fireWings {
                drawFireWings(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
            }
            if render == .fireHalo {
                drawFireHalo(in: &context, headCenter: headCenter,
                             headRadius: headRadius, scale: scale, tint: tint)
            }
            if render == .sunRing {
                drawSunRing(in: &context, headCenter: headCenter,
                            headRadius: headRadius, scale: scale, tint: tint)
            }
            if render == .orbit {
                drawOrbit(in: &context, cx: cx, cy: cy, scale: scale,
                          tint: tint, style: accessory == .tideOrbit ? .water : .pebble)
            }
            if render == .fireOrbit {
                drawOrbit(in: &context, cx: cx, cy: cy, scale: scale,
                          tint: tint, style: .fire)
            }
            if render == .soulOrbit {
                drawOrbit(in: &context, cx: cx, cy: cy, scale: scale,
                          tint: tint, style: .soul)
            }
            return
        }

        switch render {
        case .crown:
            drawLeafCrown(in: &context, headCenter: headCenter,
                          headRadius: headRadius, scale: scale, tint: tint)
        case .halo:
            drawHalo(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale, tint: tint)
        case .star:
            drawStar(in: &context, headCenter: headCenter,
                     headRadius: headRadius, scale: scale, tint: tint)
        case .butterflies:
            drawButterflies(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        case .leaves:
            drawLeaves(in: &context, cx: cx, cy: cy, scale: scale, tint: tint)
        case .crystalCrown:
            drawCrystalCrown(in: &context, headCenter: headCenter,
                             headRadius: headRadius, scale: scale, tint: tint)
        case .flowerCrown:
            drawFlowerCrown(in: &context, headCenter: headCenter,
                            headRadius: headRadius, scale: scale, tint: tint)
        case .wings, .orbit, .fireOrbit, .soulOrbit, .fairyWings,
             .fireWings, .fireHalo, .sunRing:
            break
        }
    }
}
