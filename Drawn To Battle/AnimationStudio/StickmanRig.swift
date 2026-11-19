import SwiftUI
import CoreGraphics



enum Bone: String, CaseIterable, Codable, Hashable {
    case head
    case torso
    case leftUpperArm, leftForearm
    case rightUpperArm, rightForearm
    case leftThigh, leftShin
    case rightThigh, rightShin

    /// Human-readable label shown in the editor.
    var label: String {
        switch self {
        case .head: return "Head"
        case .torso: return "Torso"
        case .leftUpperArm: return "L Upper Arm"
        case .leftForearm: return "L Forearm"
        case .rightUpperArm: return "R Upper Arm"
        case .rightForearm: return "R Forearm"
        case .leftThigh: return "L Thigh"
        case .leftShin: return "L Shin"
        case .rightThigh: return "R Thigh"
        case .rightShin: return "R Shin"
        }
    }

    /// Default bone length in pose-space units (1.0 unit ≈ scaled at render time).
    var defaultLength: CGFloat {
        switch self {
        case .head: return 26
        case .torso: return 60
        case .leftUpperArm, .rightUpperArm: return 38
        case .leftForearm, .rightForearm: return 36
        case .leftThigh, .rightThigh: return 42
        case .leftShin, .rightShin: return 40
        }
    }

    /// Angles in radians are measured clockwise from "down" (0 = pointing straight down).
    var defaultAngle: CGFloat {
        switch self {
        case .torso: return .pi          
        case .head: return 0
        case .leftUpperArm: return 0.35
        case .leftForearm: return 0.2
        case .rightUpperArm: return -0.35
        case .rightForearm: return -0.2
        case .leftThigh: return 0.15
        case .leftShin: return 0.05
        case .rightThigh: return -0.15
        case .rightShin: return -0.05
        }
    }

    /// Bones that can be directly rotated by the user.
    static var rotatable: [Bone] { Bone.allCases }
}

// MARK: - Pose

/// A single articulated stickman configuration.
struct StickmanPose: Codable, Equatable {
    /// Root position (the hip) in canvas coordinates.
    var root: CGPoint
    /// Cumulative rotation of the whole figure (radians).
    var bodyRotation: CGFloat
    /// Global scale multiplier.
    var scale: CGFloat
    /// Stroke thickness.
    var thickness: CGFloat
    /// Stroke color, stored as ARGB UInt32 for Codable simplicity.
    var colorARGB: UInt32
    /// Rotation of each rotatable bone, in radians, relative to its parent.
    var angles: [Bone: CGFloat]

    init(
        root: CGPoint = CGPoint(x: 200, y: 430),
        bodyRotation: CGFloat = 0,
        scale: CGFloat = 1,
        thickness: CGFloat = 6,
        colorARGB: UInt32 = 0xFF0094F7,
        angles: [Bone: CGFloat]? = nil
    ) {
        self.root = root
        self.bodyRotation = bodyRotation
        self.scale = scale
        self.thickness = thickness
        self.colorARGB = colorARGB
        self.angles = angles ?? Dictionary(uniqueKeysWithValues: Bone.allCases.map { ($0, $0.defaultAngle) })
    }

    var color: Color {
        Color(hex: colorARGB)
    }

    static func == (lhs: StickmanPose, rhs: StickmanPose) -> Bool {
        lhs.root == rhs.root
            && lhs.bodyRotation == rhs.bodyRotation
            && lhs.scale == rhs.scale
            && lhs.thickness == rhs.thickness
            && lhs.colorARGB == rhs.colorARGB
            && lhs.angles == rhs.angles
    }
}

// MARK: - Battle renderer

enum StickmanRenderer {
    /// Draws a stickman with its hip anchored at `origin`. `mirror` flips it
    /// horizontally around the origin (used for facing left/right).
    static func draw(
        _ context: inout GraphicsContext,
        pose: StickmanPose,
        hipAt origin: CGPoint,
        mirror: Bool = false,
        tint: Color? = nil
    ) {
        let color = tint ?? pose.color
        var t = CGAffineTransform(translationX: origin.x, y: origin.y)
        t = t.scaledBy(x: mirror ? -1 : 1, y: 1)
        t = t.translatedBy(x: -pose.root.x, y: -pose.root.y)

        var path = Path()
        path.addPath(StickmanKinematics.skeletonPath(for: pose), transform: t)
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: pose.thickness, lineCap: .round, lineJoin: .round)
        )

        let head = StickmanKinematics.headCircle(for: pose)
        let c = head.center.applying(t)
        let r = head.radius
        context.fill(
            Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
            with: .color(color)
        )
    }
}


/// Maps pose-space coordinates (a fixed 400×520 design space) onto any canvas size,
/// keeping the figure visible regardless of aspect ratio.
struct PoseViewTransform {
    static let space = CGSize(width: 400, height: 520)

    let scale: CGFloat
    let offsetX: CGFloat
    let offsetY: CGFloat

    init(canvasSize: CGSize, bottomMargin: CGFloat = 18) {
        let s = min(canvasSize.width / Self.space.width, canvasSize.height / Self.space.height)
        scale = s
        offsetX = (canvasSize.width - Self.space.width * s) / 2
        offsetY = canvasSize.height - Self.space.height * s - bottomMargin
    }

    func toCanvas(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * scale + offsetX, y: p.y * scale + offsetY)
    }

    func toPose(_ p: CGPoint) -> CGPoint {
        CGPoint(x: (p.x - offsetX) / scale, y: (p.y - offsetY) / scale)
    }

    func transformedPath(_ path: Path) -> Path {
        var out = Path()
        out.addPath(
            path,
            transform: CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: offsetX, ty: offsetY)
        )
        return out
    }
}

// MARK: - Forward kinematics

/// A resolved point in canvas space for a named joint/bone end.
enum JointPoint: String, CaseIterable {
    case hip
    case neck
    case headTop
    case leftShoulder, leftElbow, leftHand
    case rightShoulder, rightElbow, rightHand
    case leftKnee, leftFoot
    case rightKnee, rightFoot

    /// Which bone drives this joint, and how far along it (0 = start, 1 = end).
    var boneAnchor: (bone: Bone, t: CGFloat) {
        switch self {
        case .hip: return (.torso, 0)
        case .neck: return (.torso, 1)
        case .headTop: return (.head, 1)
        case .leftShoulder: return (.leftUpperArm, 0)
        case .leftElbow: return (.leftUpperArm, 1)
        case .leftHand: return (.leftForearm, 1)
        case .rightShoulder: return (.rightUpperArm, 0)
        case .rightElbow: return (.rightUpperArm, 1)
        case .rightHand: return (.rightForearm, 1)
        case .leftKnee: return (.leftThigh, 1)
        case .leftFoot: return (.leftShin, 1)
        case .rightKnee: return (.rightThigh, 1)
        case .rightFoot: return (.rightShin, 1)
        }
    }
}

enum StickmanKinematics {
    /// Compute the canvas-space position of every joint for a pose.
    static func resolve(_ pose: StickmanPose) -> [JointPoint: CGPoint] {
        var points: [JointPoint: CGPoint] = [:]

        func rotate(_ v: CGPoint, by a: CGFloat) -> CGPoint {
            CGPoint(x: v.x * cos(a) - v.y * sin(a), y: v.x * sin(a) + v.y * cos(a))
        }
        func boneVector(_ bone: Bone, worldAngle: CGFloat) -> CGPoint {
            let len = bone.defaultLength * pose.scale
            // Angle 0 points straight down in world space.
            let unit = CGPoint(x: 0, y: len)
            return rotate(unit, by: worldAngle)
        }

        // Hip root, then walk the chain.
        let hip = pose.root
        points[.hip] = hip

        // Torso grows upward from the hip: world angle = bodyRotation + torsoAngle.
        let torsoWorld = pose.bodyRotation + (pose.angles[.torso] ?? .pi)
        let torsoVec = boneVector(.torso, worldAngle: torsoWorld)
        let neck = CGPoint(x: hip.x + torsoVec.x, y: hip.y + torsoVec.y)
        points[.neck] = neck

        // Head is attached above the neck (offset so it does not sit on the neck joint).
        let headWorld = torsoWorld + (pose.angles[.head] ?? 0)
        let headVec = boneVector(.head, worldAngle: headWorld)
        points[.headTop] = CGPoint(x: neck.x + headVec.x, y: neck.y + headVec.y)

        // Arms hang from points along the torso (shoulders at 88% up the torso).
        let shoulderT: CGFloat = 0.88
        let shoulderBase = CGPoint(
            x: hip.x + torsoVec.x * shoulderT,
            y: hip.y + torsoVec.y * shoulderT
        )
        points[.leftShoulder] = shoulderBase
        points[.rightShoulder] = shoulderBase

        for (elbowJoint, handJoint, upper, lower) in [
            (JointPoint.leftElbow, JointPoint.leftHand, Bone.leftUpperArm, Bone.leftForearm),
            (JointPoint.rightElbow, JointPoint.rightHand, Bone.rightUpperArm, Bone.rightForearm),
        ] {
            let upperWorld = pose.bodyRotation + (pose.angles[upper] ?? 0)
            let upperVec = boneVector(upper, worldAngle: upperWorld)
            let elbow = CGPoint(x: shoulderBase.x + upperVec.x, y: shoulderBase.y + upperVec.y)
            points[elbowJoint] = elbow
            let lowerWorld = upperWorld + (pose.angles[lower] ?? 0)
            let lowerVec = boneVector(lower, worldAngle: lowerWorld)
            points[handJoint] = CGPoint(x: elbow.x + lowerVec.x, y: elbow.y + lowerVec.y)
        }

        // Legs grow from the hip.
        for (kneeJoint, footJoint, thigh, shin) in [
            (JointPoint.leftKnee, JointPoint.leftFoot, Bone.leftThigh, Bone.leftShin),
            (JointPoint.rightKnee, JointPoint.rightFoot, Bone.rightThigh, Bone.rightShin),
        ] {
            let thighWorld = pose.bodyRotation + (pose.angles[thigh] ?? 0)
            let thighVec = boneVector(thigh, worldAngle: thighWorld)
            let knee = CGPoint(x: hip.x + thighVec.x, y: hip.y + thighVec.y)
            points[kneeJoint] = knee
            let shinWorld = thighWorld + (pose.angles[shin] ?? 0)
            let shinVec = boneVector(shin, worldAngle: shinWorld)
            points[footJoint] = CGPoint(x: knee.x + shinVec.x, y: knee.y + shinVec.y)
        }

        return points
    }

    /// Convert a pose to a drawable path.
    static func skeletonPath(for pose: StickmanPose) -> Path {
        let p = resolve(pose)
        var path = Path()

        func line(_ a: JointPoint, _ b: JointPoint) {
            guard let pa = p[a], let pb = p[b] else { return }
            path.move(to: pa)
            path.addLine(to: pb)
        }

        line(.hip, .neck)                 // torso
        line(.leftShoulder, .leftElbow)
        line(.leftElbow, .leftHand)
        line(.rightShoulder, .rightElbow)
        line(.rightElbow, .rightHand)
        line(.hip, .leftKnee)
        line(.leftKnee, .leftFoot)
        line(.hip, .rightKnee)
        line(.rightKnee, .rightFoot)
        // Note: no neck→head-top line — the filled head circle IS the head.

        return path
    }

    /// Circle for the head, centered slightly beyond the neck along the head bone.
    static func headCircle(for pose: StickmanPose) -> (center: CGPoint, radius: CGFloat) {
        let p = resolve(pose)
        guard let neck = p[.neck], let top = p[.headTop] else {
            return (pose.root, 12)
        }
        let dx = top.x - neck.x, dy = top.y - neck.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0.001 else { return (neck, 12) }
        let ux = dx / len, uy = dy / len
        let radius = max(8, 13 * pose.scale)
        // Center the head circle a bit past the neck along the head direction.
        let center = CGPoint(x: neck.x + ux * (radius * 0.6), y: neck.y + uy * (radius * 0.6))
        return (center, radius)
    }
}
