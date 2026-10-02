# Brief: fighter sprite sheets, stages and icon for Clash of the Crossing

Paste this whole brief into ChatGPT (image generation on), then say **start**.
It is written to be worked through unattended, like the sprite brief for
Aetheria Rising (`aetheria.rising/docs/design/sprite-pack-prompts.md`), and
uses the same rules, so the two games look like one world.

Drop what it makes into `art-inbox/` as listed under **Where files go**, then
run `swift Tools/import-art.swift` from the repo root. Every sheet that
arrives replaces the drawn stand-in for that hero or stage; anything missing
keeps the stand-in, so the game ships at any point.

---

## Your goal

Generate the images in the **Job list** for *Aetheria Rising: Clash of the
Crossing*, a 2D fighting game for iPhone and iPad starring the thirteen
commanders of *Aetheria Rising*: heroes from ancient Rome, Egypt, Persia and
Han China drawn together by the mist of the Crossing.

Work through the job list on your own, in order. Don't stop to ask
questions; where something is unclear, make a sensible choice that fits the
style and note it in the manifest. If you run out of room, stop at the end of
a hero and give me the manifest so far. When I say "continue", resume at the
first job the manifest doesn't mark as done.

## Rules for every fighter image

1. **Style:** painted, semi-realistic illustration. Rich natural colours, warm
   light from the upper left, soft painterly shading, crisp clean edges and a
   subtle dark outline so the figure reads clearly at small sizes. Match the
   attached hero portrait for face, colouring, costume and equipment.
2. **Background:** transparent. If you can't make it transparent, use a flat
   solid `#FF00FF` magenta, and use it for every image. Never draw ground,
   cast shadows, scenery, text, labels, frame numbers, borders or grid lines.
3. **Fighter view:** a side view, the hero facing **right**, seen from level
   height (a classic 2D fighting game). Weapon hand nearest the enemy.
4. **Full body:** the whole figure is visible in every frame, head to toe,
   never cropped, including weapons at full extension.
5. **Consistency:** make the hero's `reference` first, from the portrait. For
   every sheet after that, give the reference as the input image and keep the
   same face, build, colours, clothing, armour, equipment, size and view.
6. **Grid:** frames sit in an evenly spaced grid, read left to right and then
   top to bottom. Each cell holds exactly one pose, centred. The figure is the
   same scale in every cell and its feet sit on the same line in every cell
   (except `jump`, `air` and `ko`, which leave the ground). Leave a clear gap
   around each figure: nothing may touch or cross into another cell.
7. **In place:** walks and strikes happen on the spot; the game moves the
   figure. Lunges may lean forward but the back foot stays in its cell.
8. **Loops** flow from the last frame back into the first. **One-shot**
   actions play once and hold on the last frame.
9. **No gore:** blows and defeats show no blood or wounds.

| Frames | Grid | Image size |
| --- | --- | --- |
| 4 | 2 columns × 2 rows | 1024 × 1024 |
| 6 | 3 columns × 2 rows | 1536 × 1024 |
| 8 | 4 columns × 2 rows | 1536 × 1024 |
| 12 | 4 columns × 3 rows | 1536 × 1024 |

## Actions (every hero)

`[WEAPON]`, `[SPECIAL]` and `[SUPER]` are filled in per hero below.

| Action | Frames | Plays | What happens |
| --- | --- | --- | --- |
| `reference` | 1 | — | Fighting stance, side view facing right, [WEAPON] ready. Square image, one figure, centred. |
| `idle` | 4 | loop | Fighting stance, breathing: shoulders rise in 2–3, settle in 4. Feet don't move. |
| `walk` | 8 | loop | A guarded step forward in stance, never turning away. Frames 1–4 front foot steps, 5–8 back foot follows. |
| `guard` | 4 | loop | Braced behind weapon or shield, weight back, chin down; a slight push in 2–3. |
| `jump` | 4 | once | 1 crouch, 2 springing up, 3 tucked at the top, 4 falling with legs reaching down. |
| `light` | 6 | once | A quick strike with [WEAPON]: 1–2 small wind-up, 3–4 snap out at full extension, 5–6 back to stance. |
| `heavy` | 6 | once | A big committed blow with [WEAPON]: 1–2 deep wind-up, 3–4 full-body strike, 5–6 heavy recovery. |
| `air` | 4 | once | In mid-air, legs tucked, a downward strike with [WEAPON]: 1 raise, 2–3 strike, 4 follow-through. |
| `throw` | 6 | once | 1–2 reach and grab an unseen opponent, 3–4 heave them over the hip, 5–6 back to stance. Draw only the hero. |
| `special` | 6 | once | [SPECIAL]. 1–2 wind-up, 3–4 the move at its peak, 5–6 recover. Effects (arrows, dust, light) may be drawn small and attached to the hero; nothing detached. |
| `super` | 8 | once | [SUPER]. 1–2 a dramatic gathering pose with a soft glow in the hero's colour, 3–6 the attack, 7–8 a proud recovery. |
| `hit` | 4 | once | Struck: 1 head snaps back, 2 staggering back, 3 off balance, 4 regaining stance. |
| `ko` | 12 | once | Defeated: recoils 1–2, staggers 3–4, sinks 5–7, topples backward 8–10, lies on the back 11–12. Each frame a small step from the last. |
| `victory` | 6 | loop | A victory pose true to the hero (see job list), with a small repeating motion. |

## Job list

Attach each hero's portrait from `App/Resources/Portraits/<id>.jpg` when making
their `reference`. Make the actions in the order of the table above.

| id | Hero | Look | [WEAPON] | [SPECIAL] | [SUPER] | Victory |
| --- | --- | --- | --- | --- | --- | --- |
| `gaius` | Gaius Aurelius, Rome | weathered legionary in his forties, close grey hair, jaw scar, battered lorica segmentata, red scarf | gladius and a red scutum | Shield Wall: raises the scutum in a braced wall, then smashes forward with it | The Line Holds: advances behind the shield driving five blows | Plants the scutum and rests a hand on it, nodding |
| `zhao_lin` | Zhao Lin, Han | young crossbowman, lacquered leather armour, topknot with red cord | bronze-trigger repeating crossbow (melee: stock strikes and kicks) | Repeating Bolts: braces and looses two bolts | Watchtower of Juyan: kneels and looses a storm of bolts | Shoulders the crossbow and bows formally |
| `tahmina` | Tahmina, Persia | lean horse-archer woman, quilted riding coat, felt cap, wind-blown dark braid | steppe-horn recurve bow and a knife | Parting Shot: springs backward and looses an arrow mid-leap | Rakhsh Runs: a ghostly white stallion surges past her as she looses arrows | Laughs, bow raised over her head |
| `marcus_varro` | Marcus Varro, Rome | confident cavalry prefect, plumed helmet, scale armour, red cape, silvered face mask at his belt | cavalry spatha | Flanking Charge: a sprinting lunge, blade low and forward | Silvered Mask: masked, a cavalry charge with a spectral grey horse | Holds the mask at his side, offers a hand |
| `khepri` | Kepri, Egypt | wiry chariot scout, linen kilt, leather scale vest, kohl-lined eyes | khopesh | Desert Wind: a low dash that kicks up a cloud of sand | Rising Sun Chariot: a golden spectral chariot thunders through | Spins the khopesh and grins |
| `bardiya` | Bardiya, Persia | tall Immortal guardsman, embroidered robe over scale armour, stern bearded face | spear with a gold pomegranate butt and a wicker shield | Ten Thousand Stand: a slow armoured stride ending in a spear thrust | The Immortals: rows of spectral spearmen thrust beside him | Spear grounded, arms folded, unimpressed |
| `wei_jian` | Wei Jian, Han | general in red-lacquered lamellar, long black beard, red cape | jian sword (command seal at the belt) | Iron Formation: plants his feet, sword vertical, a ring of force | Red General's Seal: a whirl of the jian ending in a stamp of the seal | Sheathes the jian, bows slightly |
| `meritamun` | Meritamun, Egypt | high priestess, white pleated linen, golden broad collar, vulture crown | gold sun-staff with a sistrum | Eye of Horus: raises the staff and sends a slow orb of sunlight | Scales of Ma'at: lifts the staff as a pillar of light falls ahead | Shakes the sistrum serenely |
| `arsames` | Arsamis, Persia | satrap in purple and gold riding coat, tall cap, gold torque | akinaka short sword | Satrap's Levy: raises the sword to signal; a horseman's shadow behind | Golden Rhyton: lifts a golden rhyton as riders surge past | Raises the rhyton in a toast |
| `livia` | Livia Drusilla, Rome | noblewoman in a white stola and red palla, golden laurel wreath | eagle standard used as a staff | Imperial Resolve: lifts the standard, a calm golden glow | Laurel of Concord: the standard comes down again and again in light | Stands composed, standard upright |
| `nefru` | Nefru, Egypt (Kush) | royal archer, blue and gold headdress, gold collar, white kilt | golden bow | Sunlit Volley: looses arrows high into the sky | Bow of the South: draws a great golden bow, one blazing shot | Bow lowered, chin raised proudly |
| `atossa` | Atossa, Persia | queen in scale riding armour, jewelled diadem, teal veil | royal lance with a teal pennant | Royal Charge: a charging lance thrust, a white horse's shadow behind | House of Cyrus: spectral royal guard charge behind her banner | Lance raised, veil blowing |
| `mei_lin` | Mei Lin, Han | court strategist, layered green silk robes, jade pendant, hair pins | iron folding fan | Thousand Bolt Stratagem: a fan sweep throwing a gust, a glowing seal glyph at her feet | The Thousandth Plan: seals light up all around her | Snaps the fan shut and smiles |

## Stages (after the fighters)

Five wide paintings per stage would be ideal, but three layers are enough.
Same painted style, **no people or animals**, nothing in the lowest fifth of
`far` and `mid` but the horizon, since fighters stand there.

| File | Size | Content |
| --- | --- | --- |
| `<stage>-far.png` | 2048 × 1024, opaque | sky and distant scenery |
| `<stage>-mid.png` | 2048 × 1024, transparent | middle-distance architecture, open sky above it |
| `<stage>-floor.png` | 2048 × 256, opaque | the ground the fighters stand on, seen from slightly above |

| stage | Setting |
| --- | --- |
| `forum` | The Forum at dusk: temples, colonnades, braziers, a red sunset |
| `nile` | Banks of the Nile: pyramids, obelisks, palms, golden afternoon |
| `persepolis` | The Gate of All Nations: bull-capital columns, Zagros mountains, amber light |
| `greatWall` | Juyan watchtower on the Great Wall at dusk, red lanterns on a rope |
| `crossing` | The Crossing: silver mist, broken floating stones, the white tower of Aeterna with a blue beacon |

## Icon and store art

- `icon.png` — 1024 × 1024, opaque, no text: a gladius crossed with a jian
  inside a gold laurel wreath on crimson, painted like Aetheria Rising's icon.
- `key-art.png` — 2732 × 2048, opaque: all thirteen commanders facing the
  viewer in a loose crowd before the white tower in the mist, the Echo (a
  blue-grey mist figure) behind them. Leave the top third calm for a logo.

## Where files go

```
art-inbox/fighters/<id>/<action>.png     e.g. art-inbox/fighters/gaius/light.png
art-inbox/stages/<stage>-far.png         e.g. art-inbox/stages/forum-far.png
art-inbox/icon.png
art-inbox/key-art.png
```

## Manifest

Keep a table as you go, one row per image:

| id | action | frames | grid | status | notes |
| --- | --- | --- | --- | --- | --- |
