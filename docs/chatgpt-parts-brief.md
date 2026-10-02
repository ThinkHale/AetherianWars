# Brief: painted fighter parts for Clash of the Crossing

Thirteen images in all, one per hero. Paste this brief into ChatGPT (image
generation on), attach the hero's portrait from `App/Resources/Portraits/`,
and ask for that hero's **parts sheet**. Save each result as
`art-inbox/fighters/<id>/parts.png`, then run `swift Tools/import-art.swift`.

The game cuts the sheet into pieces and moves them on its skeleton, so one
image animates every move: stance, walk, strikes, specials, falls. This is
the same cutout technique used by many 2D games, and it keeps every hero true
to their portrait.

---

## Your goal

Paint a **character parts sheet** for a 2D fighting game: one hero from
*Aetheria Rising*, taken apart into the separate body pieces a skeletal
animation rig needs. The attached portrait defines the hero's face,
colouring, costume, armour and equipment. Match it exactly.

## Rules

1. **Style:** painted, semi-realistic illustration matching the portrait: rich
   natural colours, warm light from the upper left, soft painterly shading,
   crisp clean edges, a subtle dark outline.
2. **Background:** transparent. If you can't make it transparent, use flat
   solid `#FF00FF` magenta. No ground, shadows, scenery, text, labels or grid
   lines.
3. **Image:** 1536 × 1024, a grid of **4 columns × 3 rows**, one piece per cell,
   centred, with clear space around it. Nothing may touch or cross a cell
   edge.
4. **Side view, facing right.** Every piece is drawn as it would look on the
   hero standing in profile facing right, at the **same scale** as the full
   figure in cell 12.
5. **Joint ends:** limbs are drawn hanging **straight down**, the joint they
   hang from at the **top**, rounded off so they overlap neatly when rotated.
6. **No gore**, no cut flesh: pieces end in rounded, clothed or armoured
   joints, like a doll's.

## The twelve cells (left to right, top to bottom)

| Cell | Piece | How to draw it |
| --- | --- | --- |
| 1 | **Head** | The head and neck in profile facing right, with hair and headgear. Neck at the bottom. |
| 2 | **Torso** | Shoulders to hips, side view, chest facing right, with armour or clothing. Hips at the bottom, neck opening at the top. No arms, no legs, no head. |
| 3 | **Upper arm** | Shoulder at the top, elbow at the bottom, with sleeve or armour. |
| 4 | **Forearm and hand** | Elbow at the top, hand at the bottom, the hand closed in a fist as if gripping. |
| 5 | **Thigh** | Hip at the top, knee at the bottom. |
| 6 | **Shin and foot** | Knee at the top; the foot at the bottom, pointing right, with sandal or boot. |
| 7 | **Skirt** | Whatever hangs from the waist (tunic hem, kilt, robe skirt, coat skirts), waist at the top, as if hanging straight down. Leave empty if the hero wears none. |
| 8 | **Cape** | Cape, cloak, veil or scarf tail hanging straight down from the shoulders, top edge at the top. Leave empty if none. |
| 9 | **Weapon** | The main weapon alone, **vertical, grip at the bottom, point or head at the top**. |
| 10 | **Off-hand** | Shield, quiver or second item, facing right. Leave empty if none. |
| 11 | **Back hair** | A braid, ponytail or veil that hangs behind the head, top at the top. Leave empty if none. |
| 12 | **Full figure** | The whole hero assembled from these pieces, standing in a fighting stance, side view facing right. Used to check scale and likeness. |

## Heroes

| id | Hero | Weapon (cell 9) | Off-hand (cell 10) |
| --- | --- | --- | --- |
| `gaius` | Gaius Aurelius | gladius | red scutum |
| `zhao_lin` | Zhao Lin | bronze-trigger repeating crossbow, stock at the bottom | quiver |
| `tahmina` | Tahmina | steppe-horn recurve bow, upright | quiver |
| `marcus_varro` | Marcus Varro | cavalry spatha | none (mask at belt, on the torso) |
| `khepri` | Kepri | khopesh | none |
| `bardiya` | Bardiya | spear with a gold pomegranate butt | wicker shield |
| `wei_jian` | Wei Jian | jian sword | none |
| `meritamun` | Meritamun | gold sun-staff topped with a sistrum | none |
| `arsames` | Arsamis | akinaka short sword | none |
| `livia` | Livia Drusilla | eagle standard on a pole | none |
| `nefru` | Nefru | golden bow, upright | quiver |
| `atossa` | Atossa | royal lance with a teal pennant | none |
| `mei_lin` | Mei Lin | iron folding fan, open, handle at the bottom | none |

Optional, later: the full animated sheets in `docs/chatgpt-art-brief.md`
replace a hero's parts entirely if you ever want frame-by-frame animation.
