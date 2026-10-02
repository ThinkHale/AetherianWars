import CoreGraphics
import FightCore

/// Joint angles for the fighter's skeleton, in radians. Limbs hang straight
/// down at 0; a positive angle swings a limb forward (toward the enemy). The
/// torso stands upright at 0 and leans forward with negative angles. Elbows
/// bend forward (positive); knees bend back (negative).
struct Pose {
    var hipX: CGFloat = 0
    var hipY: CGFloat = 0
    var spin: CGFloat = 0
    var torso: CGFloat = 0
    var head: CGFloat = 0
    var shoulderF: CGFloat = 0
    var elbowF: CGFloat = 0
    var shoulderB: CGFloat = 0
    var elbowB: CGFloat = 0
    var hipF: CGFloat = 0
    var kneeF: CGFloat = 0
    var hipB: CGFloat = 0
    var kneeB: CGFloat = 0
    /// Direction the weapon points in the body's frame: 0 down, π/2 forward, π up.
    var weapon: CGFloat = 2.4
    /// Blade/weapon trail strength, 0–1.
    var trail: CGFloat = 0
    /// Glow of a special or super, 0–1.
    var glow: CGFloat = 0

    static func lerp(_ a: Pose, _ b: Pose, _ t: CGFloat) -> Pose {
        let t = max(0, min(1, t))
        func m(_ x: CGFloat, _ y: CGFloat) -> CGFloat { x + (y - x) * t }
        return Pose(hipX: m(a.hipX, b.hipX), hipY: m(a.hipY, b.hipY), spin: m(a.spin, b.spin), torso: m(a.torso, b.torso),
                    head: m(a.head, b.head), shoulderF: m(a.shoulderF, b.shoulderF), elbowF: m(a.elbowF, b.elbowF),
                    shoulderB: m(a.shoulderB, b.shoulderB), elbowB: m(a.elbowB, b.elbowB), hipF: m(a.hipF, b.hipF),
                    kneeF: m(a.kneeF, b.kneeF), hipB: m(a.hipB, b.hipB), kneeB: m(a.kneeB, b.kneeB),
                    weapon: m(a.weapon, b.weapon), trail: m(a.trail, b.trail), glow: m(a.glow, b.glow))
    }
}

/// Eases: quick out of the windup, settling into the end.
private func easeOut(_ t: CGFloat) -> CGFloat { 1 - (1 - t) * (1 - t) }
private func easeInOut(_ t: CGFloat) -> CGFloat { t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2 }

/// Turns the simulation's view of a fighter into a pose for this tick.
struct PoseLibrary {
    let style: Weapon
    let archetype: Archetype
    let special: SpecialKind

    // MARK: Stances

    var stance: Pose {
        var p = Pose(hipY: -5, torso: -0.06, head: 0.04, shoulderF: 0.75, elbowF: 1.25, shoulderB: 0.35, elbowB: 1.1,
                     hipF: 0.32, kneeF: -0.34, hipB: -0.3, kneeB: -0.22, weapon: 2.4)
        switch style {
        case .spear, .lance, .standard:
            p.shoulderF = 0.55; p.elbowF = 1.45; p.weapon = style == .standard ? 2.75 : 1.62
        case .bow:
            p.shoulderF = 0.9; p.elbowF = 0.7; p.weapon = .pi
        case .crossbow:
            p.shoulderF = 0.95; p.elbowF = 0.95; p.shoulderB = 0.8; p.elbowB = 1.3; p.weapon = 1.57
        case .fan:
            p.shoulderF = 0.6; p.elbowF = 1.6; p.weapon = 2.3
        case .sistrumStaff:
            p.shoulderF = 0.4; p.elbowF = 1.2; p.weapon = 2.95
        default: break
        }
        return p
    }

    var guardPose: Pose {
        var p = stance
        p.hipY = -10; p.torso = 0.05; p.shoulderF = 1.0; p.elbowF = 1.9; p.shoulderB = 0.9; p.elbowB = 1.9
        p.hipF = 0.4; p.kneeF = -0.55; p.hipB = -0.35; p.kneeB = -0.45; p.head = -0.1
        if style == .spear || style == .lance { p.weapon = 2.2 }
        return p
    }

    func idle(_ frame: Int) -> Pose {
        var p = stance
        let breath = sin(CGFloat(frame) * 0.07)
        p.hipY += breath * 2
        p.shoulderF += breath * 0.03
        p.shoulderB -= breath * 0.03
        p.torso += breath * 0.015
        return p
    }

    func walk(_ frame: Int, forward: Bool) -> Pose {
        var p = stance
        let phase = CGFloat(frame) * (forward ? 0.2 : -0.17)
        let swing = sin(phase)
        p.hipF = 0.2 + swing * 0.45
        p.hipB = -0.15 - swing * 0.45
        p.kneeF = -0.25 - max(0, -cos(phase)) * 0.6
        p.kneeB = -0.25 - max(0, cos(phase)) * 0.6
        p.hipY = -4 + abs(cos(phase)) * 3
        p.shoulderB += swing * 0.15
        p.torso = forward ? -0.1 : 0.02
        return p
    }

    func dash(_ frame: Int, back: Bool) -> Pose {
        var p = stance
        if back {
            p.torso = 0.25; p.hipF = 0.7; p.kneeF = -0.2; p.hipB = 0.1; p.kneeB = -1.1; p.hipY = 6
        } else {
            p.torso = -0.45; p.hipF = 0.9; p.kneeF = -1.0; p.hipB = -0.9; p.kneeB = -0.5; p.hipY = -8
            p.shoulderF = 0.2; p.elbowF = 0.6; p.shoulderB = -0.6; p.elbowB = 0.5
        }
        return p
    }

    var crouch: Pose {
        var p = stance
        p.hipY = -26; p.hipF = 0.9; p.kneeF = -1.5; p.hipB = 0.3; p.kneeB = -1.6; p.torso = -0.15
        return p
    }

    func air(rising: Bool) -> Pose {
        var p = stance
        p.hipF = 1.2; p.kneeF = -1.7; p.hipB = 0.5; p.kneeB = -1.5
        p.torso = rising ? -0.05 : -0.15
        p.shoulderB = rising ? 1.6 : 0.6
        return p
    }

    var landing: Pose { crouch }

    // MARK: Attacks: three key poses (windup, strike, follow-through)

    private func keys(_ slot: MoveSlot) -> (Pose, Pose, Pose) {
        let s = stance
        var wind = s, hit = s, follow = s
        let thrusting = [.spear, .lance, .standard, .gladius].contains(style)
        switch slot {
        case .light1:
            wind.shoulderF = 0.5; wind.elbowF = 1.9; wind.torso = 0.04
            hit.shoulderF = 1.55; hit.elbowF = 0.05; hit.torso = -0.22; hit.hipX = 6; hit.weapon = thrusting ? 1.57 : 1.7
            hit.shoulderB = 0.0; hit.elbowB = 0.8
            follow = Pose.lerp(hit, s, 0.4)
        case .light2:
            wind.shoulderF = 2.3; wind.elbowF = 0.9; wind.torso = 0.1; wind.weapon = 3.1
            hit.shoulderF = 1.1; hit.elbowF = 0.2; hit.torso = -0.3; hit.hipX = 10; hit.weapon = thrusting ? 1.57 : 1.15
            hit.hipF = 0.6; hit.kneeF = -0.5; hit.hipB = -0.5
            follow = Pose.lerp(hit, s, 0.3); follow.shoulderF = 0.6
        case .light3:
            // A kick, braced on the back leg.
            wind.hipF = 1.3; wind.kneeF = -1.9; wind.torso = 0.15; wind.hipY = 2
            hit.hipF = 1.6; hit.kneeF = -0.05; hit.torso = 0.35; hit.hipX = 12; hit.hipB = -0.15; hit.kneeB = -0.1; hit.hipY = 4
            hit.shoulderF = 0.4; hit.shoulderB = -0.3
            follow = Pose.lerp(hit, s, 0.35)
        case .heavy:
            if thrusting {
                wind.shoulderF = 0.2; wind.elbowF = 2.2; wind.torso = 0.25; wind.hipX = -8; wind.weapon = 1.6
                hit.shoulderF = 1.6; hit.elbowF = 0; hit.torso = -0.45; hit.hipX = 22; hit.weapon = 1.57
                hit.hipF = 0.85; hit.kneeF = -0.6; hit.hipB = -0.7; hit.kneeB = -0.1; hit.hipY = -12
            } else {
                wind.shoulderF = 2.9; wind.elbowF = 0.5; wind.torso = 0.3; wind.hipX = -6; wind.weapon = 3.5
                hit.shoulderF = 0.9; hit.elbowF = 0.1; hit.torso = -0.5; hit.hipX = 20; hit.weapon = 0.95
                hit.hipF = 0.85; hit.kneeF = -0.6; hit.hipB = -0.7; hit.kneeB = -0.1; hit.hipY = -14
            }
            follow = hit; follow.shoulderF -= 0.4; follow.torso -= 0.05
        case .airLight:
            wind = air(rising: false); wind.hipF = 1.4; wind.kneeF = -2.0
            hit = wind; hit.hipF = 1.2; hit.kneeF = -0.2; hit.torso = 0.1; hit.shoulderF = 1.4; hit.elbowF = 0.2; hit.weapon = 1.6
            follow = hit
        case .airHeavy:
            wind = air(rising: false); wind.shoulderF = 3.0; wind.elbowF = 0.4; wind.torso = 0.2; wind.weapon = 3.3
            hit = wind; hit.shoulderF = 0.5; hit.elbowF = 0; hit.torso = -0.5; hit.weapon = 0.8; hit.hipF = 0.6; hit.kneeF = -0.9
            follow = hit
        case .throwAttempt:
            wind.shoulderF = 1.3; wind.elbowF = 0.6; wind.shoulderB = 1.3; wind.elbowB = 0.6; wind.torso = -0.2; wind.hipX = 4
            hit = wind; hit.shoulderF = 1.6; hit.shoulderB = 1.6; hit.elbowF = 0.2; hit.elbowB = 0.2; hit.hipX = 10
            follow = s; follow.shoulderF = 2.6; follow.shoulderB = 2.4; follow.torso = 0.3; follow.hipX = -4
        case .special, .superArt:
            (wind, hit, follow) = specialKeys(slot == .superArt)
        }
        hit.trail = slot == .light1 ? 0.5 : 1
        if slot == .special || slot == .superArt { wind.glow = 1; hit.glow = 1; follow.glow = 0.5 }
        return (wind, hit, follow)
    }

    private func specialKeys(_ isSuper: Bool) -> (Pose, Pose, Pose) {
        let s = stance
        var wind = s, hit = s, follow = s
        let kind: SpecialKind? = isSuper ? nil : special
        let shooting = isSuper ? archetype == .archer : [.volley, .partingShot, .eyeOfHorus, .sunlitVolley].contains(special)
        if shooting {
            // Drawing a bow (or levelling a crossbow, or raising the orb).
            wind.shoulderF = 1.5; wind.elbowF = 0.1; wind.shoulderB = 1.45; wind.elbowB = 1.2; wind.torso = 0.05; wind.weapon = .pi
            hit = wind; hit.shoulderB = 1.3; hit.elbowB = 2.5; hit.torso = 0.1
            if kind == .sunlitVolley { wind.shoulderF = 2.4; hit.shoulderF = 2.5; hit.torso = 0.35 }
            if kind == .eyeOfHorus { hit.shoulderF = 1.6; hit.elbowF = 0; hit.weapon = 1.57 }
            if style == .crossbow { wind.weapon = 1.57; hit.weapon = 1.57 }
            if style == .fan { wind.weapon = 2.0; hit.weapon = 1.6 }
            follow = hit
        } else {
            switch kind {
            case .counter?, .ironFormation?:
                wind = guardPose; wind.hipY = -14
                hit = wind; hit.shoulderF = 1.7; hit.elbowF = 0.1; hit.torso = -0.35; hit.hipX = 18; hit.weapon = 1.7
                follow = hit
            case .imperialResolve?:
                wind = s; wind.shoulderF = 2.6; wind.elbowF = 0.3; wind.weapon = 3.1; wind.head = 0.25; wind.torso = 0.12
                hit = wind; hit.shoulderF = 2.9
                follow = hit
            case .stratagem?, .levy?:
                wind = s; wind.shoulderF = 1.9; wind.elbowF = 0.4; wind.torso = 0.1
                hit = wind; hit.shoulderF = 1.4; hit.elbowF = 0; hit.torso = -0.15; hit.weapon = 2.0
                follow = hit
            default:
                // Charges and armoured advances: low, leaning in, weapon levelled.
                wind = s; wind.torso = -0.3; wind.hipY = -12; wind.shoulderF = 0.6; wind.elbowF = 1.8; wind.weapon = 1.6
                wind.hipF = 0.7; wind.kneeF = -0.9; wind.hipB = -0.6
                hit = wind; hit.torso = -0.55; hit.shoulderF = 1.55; hit.elbowF = 0; hit.hipX = 16; hit.weapon = 1.57
                follow = hit
            }
        }
        return (wind, hit, follow)
    }

    /// The pose for an attack `frame` ticks in.
    func attack(_ move: Move, frame: Int, connected: Bool, counterStruck: Int?, airborne: Bool) -> Pose {
        let (wind, hit, follow) = keys(move.slot)
        let base = airborne ? air(rising: false) : stance
        if let struck = counterStruck {
            let t = CGFloat(frame - struck) / 6
            return t < 1 ? Pose.lerp(wind, hit, easeOut(t)) : Pose.lerp(hit, base, CGFloat(frame - struck - 6) / CGFloat(max(1, move.recovery)))
        }
        if move.counterWindow != nil, frame <= move.lastActive {
            return Pose.lerp(base, wind, easeOut(CGFloat(frame) / 4))
        }
        let f = CGFloat(frame)
        let startup = CGFloat(max(1, move.startup))
        if f <= startup {
            // Wind up for most of the startup, then snap into the strike.
            let split = startup * 0.7
            if f <= split { return Pose.lerp(base, wind, easeInOut(f / max(1, split))) }
            return Pose.lerp(wind, hit, easeOut((f - split) / max(1, startup - split)))
        }
        if f <= CGFloat(move.lastActive) {
            let t = (f - startup) / CGFloat(max(1, move.active))
            var p = Pose.lerp(hit, follow, t)
            if move.hits > 1 { p.shoulderF += sin(f * 1.3) * 0.5; p.torso += sin(f * 1.3) * 0.08 }
            return p
        }
        let t = (f - CGFloat(move.lastActive)) / CGFloat(max(1, move.recovery))
        var p = Pose.lerp(follow, base, easeInOut(t))
        p.trail = 0
        return p
    }

    // MARK: Taking blows

    func hitstun(_ frame: Int, heavy: Bool) -> Pose {
        var p = stance
        let t = min(1, CGFloat(frame) / 5)
        p.torso = 0.38 * (1 - t * 0.3); p.head = 0.35; p.shoulderF = 0.2; p.elbowF = 0.4; p.shoulderB = -0.4; p.elbowB = 0.3
        p.hipX = -6; p.hipF = 0.5; p.kneeF = -0.4; p.hipB = -0.2
        if heavy { p.torso += 0.15; p.hipX -= 4 }
        return p
    }

    func blockstun(_ frame: Int) -> Pose {
        var p = guardPose
        p.hipX = -3 * max(0, 1 - CGFloat(frame) / 8)
        return p
    }

    /// Tumbling through the air after a launch or a heavy blow.
    func juggle(_ frame: Int, rising: Bool) -> Pose {
        var p = stance
        p.torso = 0.6; p.head = 0.4; p.shoulderF = -0.5; p.elbowF = 0.4; p.shoulderB = 1.6; p.elbowB = 0.5
        p.hipF = 1.1; p.kneeF = -0.6; p.hipB = 0.6; p.kneeB = -1.2
        p.spin = min(CGFloat(frame) * 0.09, rising ? 0.9 : 1.35)
        return p
    }

    var lyingDown: Pose {
        var p = Pose()
        p.spin = .pi / 2 * 0.98; p.hipY = -78; p.torso = 0.05; p.head = 0.2
        p.shoulderF = 0.8; p.elbowF = 0.3; p.shoulderB = 2.6; p.elbowB = 0.4; p.hipF = 0.25; p.kneeF = -0.3; p.hipB = -0.1; p.kneeB = -0.1
        return p
    }

    func getUp(_ frame: Int, of total: Int) -> Pose {
        let t = CGFloat(frame) / CGFloat(max(1, total))
        return t < 0.5 ? Pose.lerp(lyingDown, crouch, easeInOut(t * 2)) : Pose.lerp(crouch, stance, easeInOut(t * 2 - 1))
    }

    func thrown(_ frame: Int) -> Pose {
        var p = hitstun(frame, heavy: true)
        p.hipY = 6
        return p
    }

    func victory(_ frame: Int) -> Pose {
        var p = stance
        let t = min(1, CGFloat(frame) / 18)
        p.hipF = 0.15; p.kneeF = -0.05; p.hipB = -0.15; p.kneeB = -0.05; p.hipY = 0
        p.shoulderF = 0.75 + 2.2 * easeOut(t); p.elbowF = 0.3; p.weapon = 2.4 + 0.65 * easeOut(t) + sin(CGFloat(frame) * 0.05) * 0.05
        p.shoulderB = 0.2; p.elbowB = 0.5; p.torso = 0.08; p.head = 0.15
        if style == .bow { p.weapon = .pi }
        return p
    }

    func intro(_ frame: Int) -> Pose {
        // A salute: weapon raised to the brow, then into stance.
        var salute = stance
        salute.hipF = 0.1; salute.kneeF = 0; salute.hipB = -0.1; salute.kneeB = 0; salute.hipY = 0; salute.torso = 0.02
        salute.shoulderF = 1.9; salute.elbowF = 1.9; salute.weapon = 3.05
        let t = CGFloat(frame) / 40
        return t < 1 ? salute : Pose.lerp(salute, idle(frame), easeInOut(min(1, t - 1)))
    }
}
