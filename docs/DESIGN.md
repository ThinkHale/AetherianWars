# Fight design notes

The rules live in `Packages/FightCore`. Everything below is measured in ticks
at 60 a second, and in points (a fighter stands about 180 tall; the floor runs
from −700 to 700).

## The core loop

| Beats | Is beaten by |
| --- | --- |
| Strikes | Guard |
| Guard | Throws |
| Throws | Strikes (throws have 5 ticks of startup and can't catch anyone mid-hitstun) |

Throws can be broken by pressing guard + light during the 12 ticks after
being caught. Specials and supers chip through guard; normals don't.

## Normals (shared skeleton, shaped by class)

| Move | Startup | Active | Recovery | Damage | Cancels into |
| --- | --- | --- | --- | --- | --- |
| Light 1 | 5 | 3 | 9 | 34 | Light 2, Heavy, Special, Super |
| Light 2 | 6 | 3 | 10 | 36 | Light 3, Heavy, Special, Super |
| Light 3 | 9 | 4 | 16 | 58 | Special, Super |
| Heavy | 12 | 4 | 19 | 88 | Special, Super |
| Air light | 5 | 8 | 8 | 44 | Air heavy |
| Air heavy | 8 | 8 | 12 | 78 | — |
| Throw | 5 | 2 | 26 | 112 | — |

Light chains also continue on a whiff once the swing ends, which keeps touch
play forgiving. Every other cancel needs the blow to connect (hit or guard).
Inputs are buffered for 8 ticks.

Damage scales by 10% per hit already taken in a combo (down to 35%). Counter
hits (striking an opponent in their startup) add 20% damage and 6 ticks of
hitstun. Juggled fighters fall out after four extra hits.

## Classes

| | Vigour | Walk | Dash | Power | Notes |
| --- | --- | --- | --- | --- | --- |
| Guardian | 1100 | 3.0 | 9.5 | 1.00 | takes 3% less damage; armour and counters |
| Rider | 980 | 4.1 | 12.5 | 1.00 | long reach; charges that cross up or launch |
| Archer | 960 | 3.6 | 11.0 | 1.00 | projectiles; guarded projectiles push back hard |

Individual heroes adjust these slightly (see `Roster.swift`).

## Specials

Every special comes from the hero's signature skill in the strategy game:

| Hero | Special | Shape |
| --- | --- | --- |
| Gaius | Shield Wall | counter stance (frames 4–30); a blow caught on it is answered with a knockdown bash |
| Zhao Lin | Repeating Bolts | two fast bolts |
| Tahmina | Parting Shot | backstep with invulnerable start, then an arrow |
| Marcus Varro | Flanking Charge | a charge that passes through and launches; +15% from behind |
| Kepri | Desert Wind | dash strike leaving a dust cloud that slows |
| Bardiya | Ten Thousand Stand | armoured advance (one hit) into a crushing spear thrust |
| Wei Jian | Iron Formation | armoured shockwave, then 4 s of 20% damage reduction |
| Meritamun | Eye of Horus | slow orb; a hit marks the enemy for +25% damage for 5 s |
| Arsamis | Satrap's Levy | a cavalryman rides in from behind and launches |
| Livia | Imperial Resolve | a slow rite: +70 health and +20% damage for 6 s |
| Nefru | Sunlit Volley | three arrows fall where the enemy stands |
| Atossa | Royal Charge | armoured mounted charge that launches |
| Mei Lin | Thousand Bolt Stratagem | a fan gust plus a seal under the enemy that bursts |

## Crossing Arts (supers)

Cost a full Aether meter (100). Meter comes from landing blows (9% of damage),
taking them (5%) and guarding. Each class has one shape, named and coloured
per hero: guardians advance behind five blows, riders charge the full
screen, archers loose one great multi-hit shot. All start invulnerable and
freeze the fight for a cut-in.

## Balance

`BalanceTests` plays every pair of heroes three times with equal Champion
CPUs and fails if anyone wins less than 32% or more than 68%. At 1.0 the
spread is 35–60%. CPU-versus-CPU is not proof of balance between people, but
it reliably catches a broken move.

## CPU

The CPU sees its opponent's moves after a reaction delay (24, 16, 10 or 6
ticks by difficulty) and decides once per enemy move whether to guard, so its
mistakes look like a person's. It punishes whiffs, anti-airs, breaks throws,
finishes combos, and picks a plan (approach, pressure, zone, retreat, bait)
suited to its class every half-second or so.
