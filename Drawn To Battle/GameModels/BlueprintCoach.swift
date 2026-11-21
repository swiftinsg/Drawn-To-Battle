import SwiftUI

// MARK: - Per-blueprint animation coaching
//
// Every blueprint gets its own short lesson: three move-specific key poses,
// the joint that actually sells the move, and one extra tip. The tutorial uses
// this to point at the right part of the stickman the first time a move is used.

enum BlueprintFocus: String {
    case head, torso, rightArm, leftArm, rightLeg, leftLeg
    case bothArms, bothLegs, wholeBody

    var label: String {
        switch self {
        case .head: return "HEAD"
        case .torso: return "TORSO"
        case .rightArm: return "RIGHT ARM"
        case .leftArm: return "LEFT ARM"
        case .rightLeg: return "RIGHT LEG"
        case .leftLeg: return "LEFT LEG"
        case .bothArms: return "BOTH ARMS"
        case .bothLegs: return "BOTH LEGS"
        case .wholeBody: return "WHOLE FIGURE"
        }
    }

    /// Joints highlighted on the pointer diagram (diagram space: 200 x 250).
    var points: [CGPoint] {
        switch self {
        case .head: return [CGPoint(x: 100, y: 38)]
        case .torso: return [CGPoint(x: 100, y: 100)]
        case .rightArm: return [CGPoint(x: 128, y: 88)]
        case .leftArm: return [CGPoint(x: 72, y: 88)]
        case .rightLeg: return [CGPoint(x: 120, y: 168)]
        case .leftLeg: return [CGPoint(x: 80, y: 168)]
        case .bothArms: return [CGPoint(x: 128, y: 88), CGPoint(x: 72, y: 88)]
        case .bothLegs: return [CGPoint(x: 120, y: 168), CGPoint(x: 80, y: 168)]
        case .wholeBody: return [CGPoint(x: 100, y: 140)]
        }
    }
}

struct BlueprintLesson {
    /// The three key frames that make this specific move readable.
    let poses: [String]
    /// The joint the tutorial points at.
    let focus: BlueprintFocus
    /// One move-specific extra hint.
    let tip: String
}

enum BlueprintCoach {
    static func lesson(for blueprint: MoveBlueprint) -> BlueprintLesson {
        lessons[blueprint.id] ?? fallback(for: blueprint.technique)
    }

    private static func poses(_ a: String, _ b: String, _ c: String) -> [String] { [a, b, c] }

    private static let lessons: [String: BlueprintLesson] = [
        // --- Base ---
        "jab": BlueprintLesson(
            poses: poses("GUARD — both fists tucked by the chin.",
                         "LOAD — pull the right hand back near the ribs.",
                         "SNAP — shoot the right fist straight out."),
            focus: .rightArm,
            tip: "Keep the right forearm tucked until the last frame, then pop it straight for speed."),
        "front_kick": BlueprintLesson(
            poses: poses("STANCE — weight on the left leg, right foot down.",
                         "CHAMBER — lift the right knee high toward the chest.",
                         "EXTEND — drive the right shin out and point the foot."),
            focus: .rightLeg,
            tip: "Rotate the right thigh up first, then straighten the right shin on impact."),
        "hammer_drop": BlueprintLesson(
            poses: poses("RAISE — swing both arms high overhead.",
                         "STRETCH — reach tall, fists above the head.",
                         "CRASH — hammer both fists straight down together."),
            focus: .bothArms,
            tip: "Move both upper arms together so the fists land in the same frame."),
        "lunge_step": BlueprintLesson(
            poses: poses("READY — crouch low with weight on the back leg.",
                         "PUSH — drive forward, lead leg stretching out.",
                         "ARRIVE — straighten up in a wide stance."),
            focus: .wholeBody,
            tip: "Drag the whole figure forward between frames — the root shift sells the lunge."),

        // --- Common ---
        "cross": BlueprintLesson(
            poses: poses("SET — guard with the lead hand high.",
                         "COIL — twist the torso and load the rear right fist.",
                         "DRIVE — rotate the hips and punch straight through."),
            focus: .rightArm,
            tip: "Add a little torso rotation so the rear fist travels farther."),
        "sweep": BlueprintLesson(
            poses: poses("DROP — sink into a low crouch.",
                         "WIND — bring the left leg around low.",
                         "SWEEP — whip the left shin across at ankle height."),
            focus: .leftLeg,
            tip: "Keep the sweeping leg close to the floor — a high kick won't read as a sweep."),
        "rising_knee": BlueprintLesson(
            poses: poses("BASE — stand tall, hands up.",
                         "DRIVE — thrust the right knee straight up.",
                         "CLIMB — extend the right shin up to meet the chin."),
            focus: .rightLeg,
            tip: "The power comes from the knee rising first; the shin straightens last."),
        "blink_rush": BlueprintLesson(
            poses: poses("LOAD — lean forward from the hips.",
                         "BLUR — shoot the figure forward in one big jump.",
                         "STOP — snap to a balanced stand."),
            focus: .wholeBody,
            tip: "Use only a few frames and one big root jump so the rush looks instant."),

        // --- Rare ---
        "comet_hook": BlueprintLesson(
            poses: poses("GUARD — fists up, shoulders loose.",
                         "WIND — swing the right arm wide and back.",
                         "HOOK — arc the right fist around in a loop."),
            focus: .rightArm,
            tip: "Swing the upper arm through a curve instead of a straight line — that's the hook."),
        "meteor_stomp": BlueprintLesson(
            poses: poses("LIFT — raise both arms and one knee.",
                         "HANG — hold at the top of the jump.",
                         "STOMP — bring both feet down hard together."),
            focus: .bothLegs,
            tip: "The impact reads through the legs — plant both feet in the same frame."),
        "smear_speedline": BlueprintLesson(
            poses: poses("WIND — coil the right arm far back.",
                         "STRETCH — lengthen the arm into a thin line.",
                         "ONE FRAME — snap the whole strike in a single frame."),
            focus: .rightArm,
            tip: "A smear lives in ONE frame — make the jump between poses huge."),
        "copter_spin": BlueprintLesson(
            poses: poses("WIND — coil the torso to one side.",
                         "ROTATE — spin the whole body with arms out.",
                         "LAND — stop facing forward, arms still wide."),
            focus: .wholeBody,
            tip: "Use body rotation, not just arm poses, for a full copter spin."),

        // --- Epic ---
        "aftershock": BlueprintLesson(
            poses: poses("RAISE — both arms overhead.",
                         "FIRST HIT — slam the fists down once.",
                         "AFTERSHOCK — slam down a second time in the next frame."),
            focus: .bothArms,
            tip: "Duplicate the impact pose and offset it slightly for the double hit."),
        "twin_fangs": BlueprintLesson(
            poses: poses("GUARD — both fists up.",
                         "LOAD — pull both hands back.",
                         "DOUBLE — fire both fists out together."),
            focus: .bothArms,
            tip: "Move both arms in the same frame so the two fists land as one blur."),
        "guillotine_kick": BlueprintLesson(
            poses: poses("RAISE — lift the right leg high overhead.",
                         "HOLD — suspend the heel at the top.",
                         "CHOP — drive the heel straight down."),
            focus: .rightLeg,
            tip: "The leg must travel high before it drops — that height is the guillotine."),
        "phase_lance": BlueprintLesson(
            poses: poses("CROUCH — compress into a tight coil.",
                         "PHASE — stretch the figure into a long line.",
                         "ARRIVE — collapse the line into a sharp point."),
            focus: .wholeBody,
            tip: "A big root jump with a thin, stretched pose makes the phase read instantly."),

        // --- Mythic ---
        "tornado": BlueprintLesson(
            poses: poses("COIL — twist the torso low.",
                         "WHIRL — rotate the body fast with arms wide.",
                         "SETTLE — stop in a grounded stance."),
            focus: .wholeBody,
            tip: "More rotation steps make a longer tornado; keep the feet near the root."),
        "orbital_heel": BlueprintLesson(
            poses: poses("SET — turn the hips sideways.",
                         "ORBIT — swing the right leg around in a wide arc.",
                         "CONNECT — snap the heel out at the top of the arc."),
            focus: .rightLeg,
            tip: "Swing the thigh in a circle before extending the shin."),
        "smear_comet_tail": BlueprintLesson(
            poses: poses("WIND — pull the right arm far back.",
                         "TAIL — leave a long trailing line behind the fist.",
                         "STRIKE — whip the arm through in one frame."),
            focus: .rightArm,
            tip: "The tail is the stretched pose just before impact — don't skip it."),

        // --- Legendary ---
        "supernova": BlueprintLesson(
            poses: poses("CHARGE — coil tight with arms in.",
                         "BURST — spin fast with arms flung out.",
                         "LAND — return to a wide, blazing stance."),
            focus: .wholeBody,
            tip: "Explode outward on the spin frame for the supernova feel."),
        "warp": BlueprintLesson(
            poses: poses("FOCUS — crouch and lean in.",
                         "WARP — teleport the root far forward in one frame.",
                         "APPEAR — pop up on the far side."),
            focus: .wholeBody,
            tip: "Two poses with a giant root jump make it look like teleportation."),
        "asteroid_drop": BlueprintLesson(
            poses: poses("CALL — reach both arms high.",
                         "FALL — hold at the peak.",
                         "CRATER — slam down and widen the stance."),
            focus: .bothArms,
            tip: "Widen the legs on impact to sell the crater."),

        // --- Elite / Transcendent / Omniscient ---
        "skybreak_edge": BlueprintLesson(
            poses: poses("EDGE — crouch with the lead foot forward.",
                         "CUT — surge across in a long, low line.",
                         "BREAK — snap upright at the far edge."),
            focus: .wholeBody,
            tip: "A sharp, straight root path gives the clean skybreak slice."),
        "starlit_pivot": BlueprintLesson(
            poses: poses("TURN — pivot on one foot.",
                         "PIVOT — rotate the torso through the arc.",
                         "FACE — finish facing forward, hands up."),
            focus: .torso,
            tip: "Keep the root planted and rotate the torso — that's a true pivot."),
        "smear_ghost": BlueprintLesson(
            poses: poses("GHOST ONE — right arm extended at one target.",
                         "GHOST TWO — arm in a second, impossible position.",
                         "SNAP — bridge them in one impossible frame."),
            focus: .rightArm,
            tip: "Put the arm in two wildly different places across a single frame."),
        "smear_eclipse": BlueprintLesson(
            poses: poses("DRAW — pull the right arm into a tight coil.",
                         "ARC — sweep a single unbroken curve.",
                         "ECLIPSE — finish with the fist hidden across the body."),
            focus: .rightArm,
            tip: "One smooth arc, no breaks — the whole strike is a single stroke."),
    ]

    private static func fallback(for technique: CombatTechnique) -> BlueprintLesson {
        switch technique {
        case .punch:
            return BlueprintLesson(
                poses: poses("GUARD — fists tucked by the chin.",
                             "LOAD — pull the striking arm back.",
                             "IMPACT — snap the fist straight out."),
                focus: .rightArm, tip: "Keep the final punch fully extended for one frame.")
        case .kick:
            return BlueprintLesson(
                poses: poses("SET — weight on the standing leg.",
                             "CHAMBER — lift the striking knee high.",
                             "EXTEND — drive the foot forward."),
                focus: .rightLeg, tip: "Chamber first, then extend on the impact frame.")
        case .slam:
            return BlueprintLesson(
                poses: poses("RAISE — both arms overhead.",
                             "HOLD — stretch tall at the top.",
                             "CRASH — bring both fists down hard."),
                focus: .bothArms, tip: "Land both fists in the same frame.")
        case .spin:
            return BlueprintLesson(
                poses: poses("WIND — coil to one side.",
                             "TURN — rotate the whole body.",
                             "LAND — stop facing forward."),
                focus: .wholeBody, tip: "Use body rotation, not just arm poses.")
        case .dash:
            return BlueprintLesson(
                poses: poses("CROUCH — load the back leg.",
                             "PUSH — stretch forward.",
                             "ARRIVE — snap upright."),
                focus: .wholeBody, tip: "Shift the root to sell the dash.")
        case .smear:
            return BlueprintLesson(
                poses: poses("WIND — coil the arm back.",
                             "STRETCH — lengthen into a streak.",
                             "ONE FRAME — snap the whole strike."),
                focus: .rightArm, tip: "Make the jump between poses huge.")
        }
    }
}
