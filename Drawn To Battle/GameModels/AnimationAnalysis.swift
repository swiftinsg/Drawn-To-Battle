import SwiftUI

// MARK: - Analysis result

struct AnalysisResult {
    var speed: Double = 0
    var acceleration: Double = 0
    var fluidity: Double = 0
    var alignment: Double = 0
    var followThrough: Double = 0
    var leverage: Double = 0
    var balance: Double = 0
    var timing: Double = 0
    var telegraph: Double = 0
    /// Overall 0–100 power score.
    var power: Double = 0
    /// How the power score reads in words — shown in the HUD, studio and collection.
    var powerLabel: String {
        switch power {
        case ..<25: return "SLOPPY"
        case ..<45: return "DECENT"
        case ..<65: return "CRISP"
        case ..<85: return "SHARP"
        default: return "DEVASTATING"
        }
    }
    /// Techniques detected in the animation.
    var techniques: Set<CombatTechnique> = []
    /// Frame index where the strike lands (max limb speed).
    var strikeIndex: Int = 0
}

enum AnimationAnalysis {
    static func analyze(_ project: AnimationProject) -> AnalysisResult {
        var r = AnalysisResult()
        let frames = project.frames
        guard frames.count >= 2 else {
            r.power = 15
            r.techniques = [.punch]
            return r
        }

        
        let joints: [[JointPoint: CGPoint]] = frames.map { StickmanKinematics.resolve($0.pose) }
        let n = frames.count
        let pairs = n - 1

  
        var handSpeeds: [Double] = []
        var footSpeeds: [Double] = []
        var rootSpeeds: [Double] = []
        var handDirs: [Double] = []      // angle of faster hand velocity
        var footDirs: [Double] = []
        var upperSweeps: [Double] = []   // biggest limb world-angle change per pair

        for i in 0..<pairs {
            let a = joints[i], b = joints[i + 1]
            let lh = dist(a[.leftHand], b[.leftHand])
            let rh = dist(a[.rightHand], b[.rightHand])
            let lf = dist(a[.leftFoot], b[.leftFoot])
            let rf = dist(a[.rightFoot], b[.rightFoot])
            handSpeeds.append(Double(max(lh, rh)))
            footSpeeds.append(Double(max(lf, rf)))
            rootSpeeds.append(Double(dist(a[.hip], b[.hip])))

            handDirs.append(dir(a[(lh >= rh) ? .leftHand : .rightHand] ?? .zero,
                                b[(lh >= rh) ? .leftHand : .rightHand] ?? .zero))
            footDirs.append(dir(a[(lf >= rf) ? .leftFoot : .rightFoot] ?? .zero,
                                b[(lf >= rf) ? .leftFoot : .rightFoot] ?? .zero))

            var sweep = 0.0
            for limb in [Bone.leftUpperArm, .rightUpperArm, .leftForearm, .rightForearm,
                         .leftThigh, .rightThigh, .leftShin, .rightShin] {
                let w1 = worldAngle(limb, pose: frames[i].pose)
                let w2 = worldAngle(limb, pose: frames[i + 1].pose)
                sweep = max(sweep, Double(abs(wrapAngle(w2 - w1))))
            }
            upperSweeps.append(sweep)
        }

        let maxHand = handSpeeds.max() ?? 0
        let maxFoot = footSpeeds.max() ?? 0
        let maxLimb = max(maxHand, maxFoot, 0.001)
        let strikePair = index(of: maxLimb, in: zip(handSpeeds, footSpeeds).map { max($0, $1) })
        let strikeFrame = min(strikePair + 1, n - 1)
        r.strikeIndex = strikeFrame

        // --- Metrics ---
        r.speed = clamp01(maxLimb / 90)

        let meanSpeed = mean(handSpeeds + footSpeeds)
        let variance = mean((handSpeeds + footSpeeds).map { pow($0 - meanSpeed, 2) })
        r.acceleration = clamp01(variance / (pow(meanSpeed, 2) + 0.001) / 1.4)

   
        let dominantDirs = maxHand >= maxFoot ? handDirs : footDirs
        if dominantDirs.count >= 2 {
            var cosSum = 0.0
            for i in 1..<dominantDirs.count {
                cosSum += max(0, cos(dominantDirs[i] - dominantDirs[i - 1]))
            }
            r.fluidity = cosSum / Double(dominantDirs.count - 1)
        }

     
        let threshold = maxLimb * 0.7
        let window = stride(from: 0, to: pairs, by: 1).filter { max(handSpeeds[$0], footSpeeds[$0]) >= threshold }
        if window.count >= 2 {
            var align = 0.0
            for j in 1..<window.count {
                let i = window[j], prev = window[j - 1]
                let d1 = (maxHand >= maxFoot ? handDirs : footDirs)[prev]
                let d2 = (maxHand >= maxFoot ? handDirs : footDirs)[i]
                align += max(0, cos(d2 - d1))
            }
            r.alignment = align / Double(window.count - 1)
        } else {
            r.alignment = 0.5
        }

        // Follow-through: extension of the striking limb at the strike frame.
        let (start, end, len): (JointPoint, JointPoint, Double) =
            maxHand >= maxFoot ? ((maxHandOf(joints[strikeFrame]) == .leftHand ? .leftShoulder : .rightShoulder),
                                  maxHandOf(joints[strikeFrame]), 74)
                               : ((maxFootOf(joints[strikeFrame]) == .leftFoot ? .hip : .hip),
                                  maxFootOf(joints[strikeFrame]), 82)
        let extensionRatio = dist(joints[strikeFrame][start], joints[strikeFrame][end]) / (len * frames[strikeFrame].pose.scale)
        r.followThrough = clamp01(extensionRatio)

        // Leverage: torso + body rotation use.
        var torsoRange = 0.0
        var bodyRange = 0.0
        for f in frames {
            torsoRange = max(torsoRange, Double(abs(wrapAngle((f.pose.angles[.torso] ?? .pi) - Bone.torso.defaultAngle))))
            bodyRange = max(bodyRange, Double(f.pose.bodyRotation))
        }
        r.leverage = clamp01((torsoRange / 1.2) * 0.5 + (bodyRange / 3.0) * 0.5)

        // Balance: root stays steady.
        let rootTravel = rootSpeeds.reduce(0, +)
        r.balance = clamp01(1 - rootTravel / 220)

        // Timing: strike should come late (anticipation), not immediately.
        let peakT = Double(strikePair) / Double(max(pairs, 1))
        let early = mean(Array((handSpeeds + footSpeeds).prefix(max(1, pairs / 3))))
        let lateness = clamp01(peakT / 0.9)
        let contrast = clamp01(1 - early / max(maxLimb, 1))
        r.timing = lateness * 0.5 + contrast * 0.5

        // Telegraph: how much faster the strike is than the windup. (Speed is
        // already measured by speed; telegraph credits the swing's power,
        // not the raw speed again — so a fast punch isn't double-counted.)
        r.telegraph = maxLimb > 0.001 ? clamp01((maxLimb - early) / maxLimb) : 0

        // --- Power (weighted) ---
        r.power = (r.speed * 0.18 + r.acceleration * 0.09 + r.fluidity * 0.12 +
                   r.alignment * 0.10 + r.followThrough * 0.13 + r.leverage * 0.10 +
                   r.balance * 0.08 + r.timing * 0.12 + r.telegraph * 0.08) * 100

        // --- Technique detection ---
        var techs: Set<CombatTechnique> = []
        if (upperSweeps.max() ?? 0) > 1.2 && maxLimb > 45 { techs.insert(.smear) }
        if bodyRange > 2.6 { techs.insert(.spin) }
        if rootTravel > 120 { techs.insert(.dash) }
        if maxHand >= maxFoot * 1.15 && r.followThrough > 0.65 { techs.insert(.punch) }
        if maxFoot > maxHand * 1.15 && r.followThrough > 0.65 { techs.insert(.kick) }
        // Slam: both hands travel a large vertical range downward.
        if handRange(joints) > 90 && handDownAt(joints, strikeFrame) { techs.insert(.slam) }
        r.techniques = techs

        return r
    }

    // MARK: Helpers

    private static func maxHandOf(_ j: [JointPoint: CGPoint]) -> JointPoint {
        (j[.leftHand]?.y ?? .infinity) <= (j[.rightHand]?.y ?? .infinity) ? .leftHand : .rightHand
    }
    private static func maxFootOf(_ j: [JointPoint: CGPoint]) -> JointPoint {
        (j[.leftFoot]?.y ?? .infinity) <= (j[.rightFoot]?.y ?? .infinity) ? .leftFoot : .rightFoot
    }

    private static func handRange(_ joints: [[JointPoint: CGPoint]]) -> Double {
        var ys: [CGFloat] = []
        for j in joints {
            ys.append(j[.leftHand]?.y ?? 0)
            ys.append(j[.rightHand]?.y ?? 0)
        }
        guard let lo = ys.min(), let hi = ys.max() else { return 0 }
        return Double(hi - lo)
    }

    private static func handDownAt(_ joints: [[JointPoint: CGPoint]], _ frame: Int) -> Bool {
        guard joints.count > 1 else { return false }
        let mid = joints[frame]
        let end = joints[joints.count - 1]
        let midHand = max(mid[.leftHand]?.y ?? 0, mid[.rightHand]?.y ?? 0)
        let endHand = max(end[.leftHand]?.y ?? 0, end[.rightHand]?.y ?? 0)
        return endHand > midHand + 20
    }

    private static func worldAngle(_ bone: Bone, pose: StickmanPose) -> CGFloat {
        switch bone {
        case .torso: return pose.bodyRotation + (pose.angles[.torso] ?? .pi)
        case .head: return pose.bodyRotation + (pose.angles[.torso] ?? .pi) + (pose.angles[.head] ?? 0)
        case .leftUpperArm: return pose.bodyRotation + (pose.angles[.leftUpperArm] ?? 0)
        case .rightUpperArm: return pose.bodyRotation + (pose.angles[.rightUpperArm] ?? 0)
        case .leftForearm: return pose.bodyRotation + (pose.angles[.leftUpperArm] ?? 0) + (pose.angles[.leftForearm] ?? 0)
        case .rightForearm: return pose.bodyRotation + (pose.angles[.rightUpperArm] ?? 0) + (pose.angles[.rightForearm] ?? 0)
        case .leftThigh: return pose.bodyRotation + (pose.angles[.leftThigh] ?? 0)
        case .rightThigh: return pose.bodyRotation + (pose.angles[.rightThigh] ?? 0)
        case .leftShin: return pose.bodyRotation + (pose.angles[.leftThigh] ?? 0) + (pose.angles[.leftShin] ?? 0)
        case .rightShin: return pose.bodyRotation + (pose.angles[.rightThigh] ?? 0) + (pose.angles[.rightShin] ?? 0)
        }
    }

    private static func dist(_ a: CGPoint?, _ b: CGPoint?) -> CGFloat {
        guard let a, let b else { return 0 }
        return hypot(a.x - b.x, a.y - b.y)
    }

    private static func dir(_ a: CGPoint?, _ b: CGPoint?) -> Double {
        guard let a, let b else { return 0 }
        return Double(atan2(b.y - a.y, b.x - a.x))
    }

    private static func wrapAngle(_ a: CGFloat) -> CGFloat {
        var a = a.truncatingRemainder(dividingBy: 2 * .pi)
        if a > .pi { a -= 2 * .pi }
        if a < -.pi { a += 2 * .pi }
        return a
    }

    private static func clamp01(_ v: Double) -> Double { min(1, max(0, v)) }
    private static func mean(_ v: [Double]) -> Double { v.isEmpty ? 0 : v.reduce(0, +) / Double(v.count) }
    private static func index(of value: Double, in v: [Double]) -> Int {
        v.firstIndex(of: value) ?? 0
    }
}
