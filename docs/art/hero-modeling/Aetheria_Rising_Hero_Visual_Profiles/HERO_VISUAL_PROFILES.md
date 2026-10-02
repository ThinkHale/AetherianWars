# Aetheria Rising — Hero visual profiles for 2D and 3D production

Prepared 2026-10-02 from the local checkout of https://github.com/ThinkHale/aetheria.rising, commit `3c97abe`. The public GitHub page returned 404 during review; this document uses the actual local repository, not an unverified online roster.

## Scope and source authority

All 13 authored catalog heroes are covered. Player-forged custom heroes are variable creations and have no fixed appearance. Canon comes from `functions/heroCatalog.js` (identity, appearance, class, signature equipment) and `functions/heroLore.js` (story and personality). `src/assets/heroes/*.webp` and `founders-atlas.jpg` were visually inspected as likeness references. Portraits do not establish unseen backs, feet, fastening systems, or exact measurements.

Each profile separates source facts from proposed production decisions. All heights, age ranges except Gaius’s stated forties, proportions, hex colors, exact garment construction, handedness, added weapons and rigging choices are proposals. Colors are art-direction targets rather than sampled pixel values. Source conflicts are called out per character so artists do not silently merge incompatible designs. These are Aetheria adaptations, not claims of archaeological accuracy.

## Shared art and modeling specification

- Style: realistic anatomy with restrained heroic stylization and painterly surfaces. Preserve recognizable faces, broad costume shapes and cultural identity. Rarity does not change human scale or mandate glowing armor.
- Work at real-world scale: meters, consistent axes and a documented forward direction. Publish neutral A-pose front/back/left/right orthographics with identical scale, plus a three-quarter beauty pose; keep perspective out of orthographics.
- Character sheets: full body, head front/profile/back, six expressions, hands, footwear, garment layers, weapon orthographics, material swatches and mount/tack where applicable. Use transparent backgrounds for isolated 2D assets; keep reference backgrounds neutral.
- Suggested starting budgets, to be adapted to target engine: hero LOD0 30–50k triangles, LOD1 12–20k, LOD2 4–8k; mount 20–35k and chariot 10–20k separately. These are planning ranges, not verified game constraints.
- Suggested textures: 2K body/face and outfit sets, 1K–2K weapons; base color, tangent-space normal, roughness, metallic and AO. Author linear data maps and sRGB base color correctly. Hair uses sculpted masses/cards; avoid expensive strand geometry for mobile.
- Topology: loops around shoulders, elbows, hips, knees, mouth and eyes; test full draw, saddle seat and shield brace before final textures. Separate rigid jewelry, weapons, armor and cloth. Use named sockets and consistent skeleton conventions.
- 2D and 3D must share the same modeling master: face, proportions, layer order, palette, handedness and accessories. Render sprites from approved models or reproduce the same turnaround; lock camera, scale, ground contact and lighting per output set.
- Animation minimum: idle, walk, run, attack/command, hit, defeat and council gesture; riders also mount idle, ride, turn and charge. Walks must visibly alternate foot contacts and passing poses. Mounted character and mount contacts must stay synchronized.
- Delivery per hero: layered source art, PNG turnarounds, material sheet, editable model source, clean FBX or GLB export as required by the receiving tool, textures, rig, animation clips and a readme identifying approved variants. A modeling profile is a brief; it is not finished artwork or a completed model.

## Roster

| Asset ID | Display name | Empire / class | Signature |
|---|---|---|---|
| `gaius` | Gaius Aurelius | Rome / guardian | Scarred Scutum |
| `zhao_lin` | Zhao Lin | Han / archer | Bronze Trigger of Juyan |
| `tahmina` | Tahmina | Persia / rider | Steppe-Horn Bow |
| `marcus_varro` | Marcus Varro | Rome / rider | Silvered Cavalry Mask |
| `khepri` | Kepri | Egypt / rider | Scarab Reins |
| `bardiya` | Bardiya | Persia / guardian | Wicker Shield of the Guard |
| `wei_jian` | Wei Jian | Han / guardian | Red General's Seal |
| `meritamun` | Meritamun | Egypt / archer | Sistrum of Karnak |
| `arsames` | Arsamis | Persia / rider | Golden Rhyton of Tribute |
| `livia` | Livia Drusilla | Rome / guardian | Laurel of Concord |
| `nefru` | Nefru | Egypt / archer | Solar Bow of Ra |
| `atossa` | Atossa | Persia / rider | Diadem of the Royal Road |
| `mei_lin` | Mei Lin | Han / archer | Jade Tally of Command |

## Gaius Aurelius — The Senator's Son

**Asset ID:** `gaius` · **Empire:** Rome · **Class:** guardian · **Rarity:** common

**Canonical appearance:** a weathered Roman legionary in his forties, close-cropped grey hair, a scar across the jaw, battered lorica segmentata and a red scarf.

**Canonical signature / skill:** Scarred Scutum / Shield Wall. Locks shields with the front line, reducing damage to allied guardians.

**Character anchor:** A senator's son handed a commission he had not earned, Gaius trained until he deserved it and rose as the officers above him fell. The higher he climbed, the more clearly he saw what Rome's victories cost the people beneath them.

**Historical status:** An original Aetheria character.

**Existing visual reference:** `src/assets/heroes/gaius.webp`.

### Proposed production design

**Body, age and silhouette:** 45–49; 178 cm; compact, broad shoulders and a thick veteran torso; 7.5 heads tall. Weight carried evenly, chin slightly lowered. Rounded rectangular silhouette: short hair, shoulder plates, broad shield.

**Face and hair:** Angular, deeply lined face; square jaw with the canon jaw scar; grey close crop, clean shave. Warm olive complexion proposed. The existing portrait establishes heavy brow, tired eyes and restrained expression. Sculpt the scar into the skin rather than painting a bright stripe.

**Costume and source reconciliation:** Portrait uses rounded bronze-looking cuirass panels rather than clearly articulated segmentata. For the modeling master, retain the catalog segmentata: overlapping horizontal torso plates, red scarf, short red tunic, leather military belt, sandals and a practical red cloak. Keep the portrait face and scarf; record armor revision explicitly.

**Palette and surface materials:** Iron plates with warm bronze fittings; oxblood cloth #8B2928; dark leather #4B3426; muted steel #73766F. Nicks cluster at shield rim and plate edges; avoid uniform noise. Cloth is matte and faded, metal scratched rather than mirror polished.

**Weapons, props and mount:** Scarred Scutum: curved rectangular shield, central boss and repaired rim, worn red painted field. Short sword in a separate belt sheath; shield in left hand, sword in right as a proposed handedness standard. Shield shape must stay broad enough to read as the defining object.

**3D construction and animation:** Split plates and straps into rigid components; preserve overlap during torso bends. Scarf and cloak get limited secondary motion. Shield requires hand grip plus forearm support. Animate a planted brace, shield wall, guarded advance and a brief thoughtful council idle.

**Required turnaround details:** Front: jaw scar, scarf and shield. Side: shield curvature and armor overlap. Back: cloak attachment, repair stitching and belt. Separate shield front/back, sword/sheath and scarf detail plates.

**Reusable concept prompt:**

> Create a full-body production character sheet of Gaius Aurelius from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a weathered Roman legionary in his forties, close-cropped grey hair, a scar across the jaw, battered lorica segmentata and a red scarf; signature item: Scarred Scutum. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Zhao Lin — The Last Loyalist

**Asset ID:** `zhao_lin` · **Empire:** Han · **Class:** archer · **Rarity:** common

**Canonical appearance:** a young Han crossbowman in lacquered leather armour, topknot tied with a red cord, a bronze-trigger crossbow across the shoulder, watchtower behind.

**Canonical signature / skill:** Bronze Trigger of Juyan / Repeating Bolts. Looses a rapid volley that strikes the two nearest enemies.

**Character anchor:** Born to a family that had served the Han for generations, Zhao Lin gave the dynasty everything until the Xiongnu wars, Nanyue and Dayuan showed him families paying for decisions made far away. He refused the title of Emperor and founded a reformed Han realm as its Guardian-King.

**Historical status:** An original Aetheria character.

**Existing visual reference:** `src/assets/heroes/zhao_lin.webp`.

### Proposed production design

**Body, age and silhouette:** 25–30; 175 cm; lean athletic build; 7.5 heads. Upright, precisely squared stance, narrow waist and clean vertical silhouette. Keep him visually young despite the senior responsibility in his story.

**Face and hair:** East Asian facial features based on the painted portrait; straight brows, alert dark eyes, smooth jaw and clean shave. Black hair in a high topknot tied with the required red cord. Controlled, serious expression; avoid adding age lines to communicate authority.

**Costume and source reconciliation:** Catalog specifies lacquered leather armor; portrait reads as red plated/lamellar armor and includes a bow and quivers. Model a red lacquered leather lamellar interpretation and replace the portrait bow loadout with the canonical bronze-trigger crossbow. Short side-split tunic, wrapped trousers and practical boots complete the proposed lower half.

**Palette and surface materials:** Red lacquer #963B30, deep brown leather #49352B, flax cloth #C9B890, patinated bronze #8F7950, black hair #211D1A. Distinguish supple leather slats from hard bronze hardware; modest frontier wear.

**Weapons, props and mount:** Bronze Trigger of Juyan is the focal mechanism of his crossbow: wood stock, transverse bow, visible string and separate trigger housing. Proposed bolt case at hip. Repeating Bolts is gameplay behavior; a specific repeating mechanism is not defined in canon and needs design approval before engineering.

**3D construction and animation:** Rigid crossbow rig with bowstring controls, hand sockets and bolt visibility. Keep finger clearance around trigger. Lamellar skirt deforms over thighs without clipping. Actions: measured aiming, rapid volley, inspection of supplies and formal salute.

**Required turnaround details:** Front/back/side views must show topknot cord and armor closures; weapon orthographics must expose trigger, string path and bolt channel. Show an armed pose and a neutral unarmed pose.

**Reusable concept prompt:**

> Create a full-body production character sheet of Zhao Lin from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a young Han crossbowman in lacquered leather armour, topknot tied with a red cord, a bronze-trigger crossbow across the shoulder, watchtower behind; signature item: Bronze Trigger of Juyan. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Tahmina — The Spirit of the Horse

**Asset ID:** `tahmina` · **Empire:** Persia · **Class:** rider · **Rarity:** common

**Canonical appearance:** a lean Persian horse-archer woman in a quilted riding coat and felt cap, recurve bow in hand, wind-blown dark braid, open grassland behind.

**Canonical signature / skill:** Steppe-Horn Bow / Parting Shot. Wheels away after each strike, loosing an arrow at the pursuer.

**Character anchor:** A master rider and horse-archer who warned that a campaign would kill its horses and then its men. It did, her stallion Rakhsh fell beneath her, and when an official called soldiers replaceable she said 'Then you will replace me' and rode away to found the Kingdom of the Wild Horse.

**Historical status:** An original Aetheria character. Her name, and her stallion Rakhsh's, recall the Shahnameh, a later Persian epic; she is not that figure.

**Existing visual reference:** `src/assets/heroes/tahmina.webp`.

### Proposed production design

**Body, age and silhouette:** 30–38; 171 cm; lean, strong back and thighs, 7.5 heads. Light riding stance with knees relaxed; diagonal braid and bow contrast with the compact felt cap.

**Face and hair:** Portrait establishes a narrow oval face, dark expressive eyes, dark braid and a warm, irreverent smile. Proposed medium olive complexion. Keep hair wind swept, with the main braid as a readable single shape rather than many fine strands.

**Costume and source reconciliation:** Quilted riding coat, felt cap, leather belt, split coat tails and fitted riding trousers. Portrait mixes brown torso panels with olive sleeves; preserve that pattern. Proposed soft riding boots and a hip quiver. Clothing must allow a full mounted torso twist.

**Palette and surface materials:** Olive wool #555A3D, saddle leather #785037, cream linen #D3C4A2, dark hair #29221D. Quilting seams and repeated elbow wear matter more than ornament. Cap is fuzzy felt; coat panels matte and padded.

**Weapons, props and mount:** Steppe-Horn Bow: recurved composite bow with horn belly, wood core and restrained sinew-backed treatment. Proposed replacement riding horse is bay; Rakhsh died in the lore and must not be presented as her living mount. A small worn tack keepsake may be proposed separately.

**3D construction and animation:** Separate braid bones, coat-tail chains and bowstring controls; mounted pose requires hip/knee clearance and shoulder rotation. Build foot and mounted rigs. Signature action is a retreating shot with a visible torso turn; include calm horse-care idle.

**Required turnaround details:** Draw cap off/on, braid back view, coat closures, bow unstrung/strung and riding tack. Mounted front/side/back sheets must preserve the same face, outfit and bow proportions.

**Reusable concept prompt:**

> Create a full-body production character sheet of Tahmina from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a lean Persian horse-archer woman in a quilted riding coat and felt cap, recurve bow in hand, wind-blown dark braid, open grassland behind; signature item: Steppe-Horn Bow. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Marcus Varro — The Son of Judea

**Asset ID:** `marcus_varro` · **Empire:** Rome · **Class:** rider · **Rarity:** rare

**Canonical appearance:** a confident Roman cavalry prefect in a plumed helmet and scale armour, silvered face mask held at his side, a grey horse behind him.

**Canonical signature / skill:** Silvered Cavalry Mask / Flanking Charge. Strikes the enemy's rear line, dealing bonus damage to archers.

**Character anchor:** Born to a Jewish family in Judea under Roman rule, Marcus entered Roman service through the auxiliaries and earned citizenship and command by courage and discipline. Seeing empire from both the ranks and the streets made him one of the four founders of a kingdom whose army exists to protect its people.

**Historical status:** An original Aetheria character.

**Existing visual reference:** `src/assets/heroes/marcus_varro.webp`.

### Proposed production design

**Body, age and silhouette:** 35–42; 182 cm; athletic cavalry build with broad chest, 7.5 heads. Open shoulders, upright seat and relaxed authority. Helmet plume adds a vertical accent; grey mount supplies a distinct companion silhouette.

**Face and hair:** Existing painting shows dark curly hair, warm brown/olive skin, strong nose, light stubble and an approachable smile. Preserve this individual face; his Judean heritage is a narrative identity, not a reason to exaggerate facial features.

**Costume and source reconciliation:** Catalog calls for scale armor and plumed helmet; portrait instead has a sculpted cuirass and an uncovered head. Use scale armor as the master, preserve red cloak and portrait face, and provide removable helmet. Proposed knee-length tunic, riding trousers and boots with practical straps.

**Palette and surface materials:** Warm bronze scales #9F7842, crimson cloak #8D2C27, leather #503727, pale silver mask #B9BAB2. Grey horse coat #A6A39A with darker mane. Metal is maintained but worked; cloak carries road dust along its hem.

**Weapons, props and mount:** Silvered Cavalry Mask must be a separate wearable/held object, with eye openings and believable strap/helmet connections. Proposed cavalry spear and sheathed sword for Flanking Charge; neither is fixed by the catalog. Grey horse is canonical; tack design is proposed.

**3D construction and animation:** Helmet/mask variants need a consistent head scale, visible face clearance and separate sockets. Mount, reins and rider use independent rigs with synchronized riding animation. Actions: flanking charge, measured council gesture and mask held low at his side.

**Required turnaround details:** Include uncovered head, helmet, masked helmet, mask interior and attachment diagram. Show horse profile and tack; verify mask matches the face without deforming the facial identity.

**Reusable concept prompt:**

> Create a full-body production character sheet of Marcus Varro from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a confident Roman cavalry prefect in a plumed helmet and scale armour, silvered face mask held at his side, a grey horse behind him; signature item: Silvered Cavalry Mask. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Kepri — The Scarab of War

**Asset ID:** `khepri` · **Empire:** Egypt · **Class:** rider · **Rarity:** rare

**Canonical appearance:** a wiry Egyptian chariot scout in a linen kilt and leather scale vest, kohl-lined eyes, holding reins of a light chariot at the desert edge.

**Canonical signature / skill:** Scarab Reins / Desert Wind. Speeds allied marches and blinds the enemy vanguard with dust.

**Character anchor:** A chariot-maker's son who mapped every road, well and ambush point in Egypt, Kepri warned the court that a campaign could not be supplied. It collapsed as he said, the rulers blamed others, and he left with scouts, engineers and displaced families to found a refuge where truth could not be overruled by pride.

**Historical status:** An original Aetheria character. His name recalls Khepri, the Egyptian scarab god of the rising sun.

**Existing visual reference:** `src/assets/heroes/khepri.webp`.

### Proposed production design

**Body, age and silhouette:** 23–30; 172 cm; wiry, long-limbed scout, 7.5 heads. Slight forward readiness, narrow torso and low ornament. Chariot silhouette is light and open rather than a massive war wagon.

**Face and hair:** Painting establishes tousled dark short hair, youthful angular face and athletic torso. Keep canonical kohl-lined eyes. Proposed warm medium-brown complexion; expression curious and alert, with a quick glance rather than a ceremonial stare.

**Costume and source reconciliation:** Linen kilt with practical wrap and belt; leather scale vest. Portrait exposes much of the torso beneath a broad decorative shoulder/collar assembly: simplify this into the specified leather vest for the master. Proposed sandals, wrist wraps and small route pouch.

**Palette and surface materials:** Sand linen #D6C49B, leather #7C5636, muted turquoise #448A86 and aged brass #A68A4B in limited accents. Dust follows fabric folds; reins darken at grip points. Avoid priestly costume overlap with Meritamun.

**Weapons, props and mount:** Scarab Reins: leather reins with small carved scarab fittings; fittings must not interfere with handling. Canonical light chariot. Proposed two-horse team, open rear, spoked wheels, shallow platform and bow case; wheel count, team and harness specifics are design decisions.

**3D construction and animation:** Chariot needs separate wheel rotation, axle, reins and horse rigs. Feet must remain inside the platform in turns. Rein loops should be modeled from hand to harness rather than floating. Actions: scan horizon, fast turn, dust-screen pass and route-map consultation.

**Required turnaround details:** Front/back/side scout sheets plus chariot top/side/front views, platform dimensions, rein routing and harness diagram. Name display is Kepri; file/asset ID remains khepri.

**Reusable concept prompt:**

> Create a full-body production character sheet of Kepri from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a wiry Egyptian chariot scout in a linen kilt and leather scale vest, kohl-lined eyes, holding reins of a light chariot at the desert edge; signature item: Scarab Reins. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Bardiya — The Fist of Persia

**Asset ID:** `bardiya` · **Empire:** Persia · **Class:** guardian · **Rarity:** rare

**Canonical appearance:** a tall Persian Immortal guardsman in an embroidered robe over scale armour, wicker shield and spear, pomegranate-butt spear, stern bearded face.

**Canonical signature / skill:** Wicker Shield of the Guard / Ten Thousand Stand. Holds the line for one round, taking no more than half damage.

**Character anchor:** A Persian commander who rose through Egypt, the Ionian Revolt and the invasion of Greece believing fear is the foundation of obedience. He broke with Atossa, whom he calls dangerously soft, took veterans, mercenaries and nobles with him, and founded a fortified Persian kingdom built to prove his Persia is the stronger one.

**Historical status:** Bardiya was the name of a real Achaemenid prince, a son of Cyrus the Great. This general, his rival kingdom, and his feud with Atossa are Aetheria fiction.

**Existing visual reference:** `src/assets/heroes/bardiya.webp`.

### Proposed production design

**Body, age and silhouette:** 40–48; 190 cm; tall, heavily built and imposing, 8 heads. Wide stance and still shoulders; long spear creates a straight vertical line, large wicker shield a dominant disk.

**Face and hair:** Portrait shows full dark beard, long dark hair under a wrapped cap, deep-set eyes and a severe expression. Proposed medium olive skin, strong cheek planes and heavy brows. Avoid villain caricature; menace comes from immobility and scrutiny.

**Costume and source reconciliation:** Embroidered Persian robe over scale armor, sleeved underlayer, wrapped headgear and substantial belt. Preserve portrait teal sleeves, patterned panels and round wicker shield. Proposed fitted trousers and ankle boots beneath the robe.

**Palette and surface materials:** Deep teal #285B59, muted crimson #7C3530, antique gold #B08B48, wicker #A18454 and steel scales #686C65. Guard equipment is orderly and well maintained; textiles carry controlled geometric embroidery.

**Weapons, props and mount:** Wicker Shield of the Guard: round woven face with metallic central boss as seen in art, practical rear grip and reinforced rim. Long spear with a pomegranate-shaped butt is canonical. Keep spearhead and butt visually separate and include a transport grip.

**3D construction and animation:** Scale armor rigid over a flexible robe; long beard needs limited bones or sculpted clumps. Spear requires two-hand and one-hand sockets. Shield cannot block his eyes in neutral pose. Actions: unmoving guard, spear plant and controlled formation brace.

**Required turnaround details:** Weapon sheet must show the pomegranate butt, spearhead and full length; shield front/back shows weave and grip. Rear robe view explains embroidery continuity and concealed armor.

**Reusable concept prompt:**

> Create a full-body production character sheet of Bardiya from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a tall Persian Immortal guardsman in an embroidered robe over scale armour, wicker shield and spear, pomegranate-butt spear, stern bearded face; signature item: Wicker Shield of the Guard. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Wei Jian — The Survivor of the Han

**Asset ID:** `wei_jian` · **Empire:** Han · **Class:** guardian · **Rarity:** epic

**Canonical appearance:** a Han general in red-lacquered lamellar armour, long black beard, holding a jian sword and command seal.

**Canonical signature / skill:** Red General's Seal / Iron Formation. Absorbs a heavy blow and rallies the front line.

**Character anchor:** The only child to survive a Han raid on his frontier village, Wei Jian was raised inside the very army that destroyed it and rose to general by winning before the first sword was drawn. Every burned village reminded him of his own, until he left the Han and became one of the four founders of a kingdom that protects families from empires.

**Historical status:** An original Aetheria character.

**Existing visual reference:** `src/assets/heroes/founders-atlas.jpg`.

### Proposed production design

**Body, age and silhouette:** 40–48; 181 cm; sturdy, broad-shouldered general, 7.5 heads. Strong triangular upper silhouette, straight planted legs and restrained gestures. Red lamellar armor should separate him instantly from Zhao Lin.

**Face and hair:** Canonical long black beard conflicts with atlas art, which shows a shorter moustache/beard. Retain the atlas facial structure and add a clearly long, controlled beard in the modeling master. Proposed medium East Asian complexion, dark eyes, black hair tied under a command headpiece.

**Costume and source reconciliation:** Red-lacquered lamellar cuirass, broad shoulder defenses, layered skirt and dark under-robe. Proposed cloth sash, fitted trousers and boots. Keep ornament sparse: his authority comes from discipline and survival, not imperial luxury.

**Palette and surface materials:** Dark red lacquer #852D29, charcoal cloth #303333, muted gold hardware #A68B58 and leather #47352C. Lacquer edges show chips; avoid making the whole armor shiny plastic. Beard remains nearly black with restrained highlights.

**Weapons, props and mount:** Jian sword and command seal are canonical. Red General’s Seal should be a compact red seal in a protective case or pouch, shown in a separate detail plate. Jian is straight and double edged; define a simple guard and matching scabbard.

**3D construction and animation:** Beard bones must clear collar and sword arm; armor skirt opens around hips. Seal is a removable hand prop. Actions: Iron Formation brace, short precise sword command, rally gesture and still reflective idle.

**Required turnaround details:** Show long beard front/side/back, seal face/handle/case, jian and scabbard. Atlas quarter is a likeness reference, not a full-body blueprint; lower body is proposed.

**Reusable concept prompt:**

> Create a full-body production character sheet of Wei Jian from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a Han general in red-lacquered lamellar armour, long black beard, holding a jian sword and command seal; signature item: Red General's Seal. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Meritamun — The Keeper of Balance

**Asset ID:** `meritamun` · **Empire:** Egypt · **Class:** archer · **Rarity:** epic

**Canonical appearance:** an Egyptian high priestess in white pleated linen and a golden broad collar, a sistrum in one hand, temple columns and incense smoke behind her.

**Canonical signature / skill:** Sistrum of Karnak / Eye of Horus. Marks the strongest enemy; allied archers deal bonus damage to it.

**Character anchor:** A daughter of Ramesses II and Nefertari who rose to High Priestess of Amun and head of a temple wealthier than provinces, Meritamun built one of the most sophisticated armies of her age. When Pharaoh, army, temple and nobles all grasped for more, she took her temple lands out of royal control and founded the Kingdom of Amun's Balance as a counterweight.

**Historical status:** Meritamun was a real daughter of Ramesses II and Nefertari who held titles in the cult of Amun. Her rise to High Priestess, her army, and her Kingdom of Amun's Balance are Aetheria fiction.

**Existing visual reference:** `src/assets/heroes/meritamun.webp`.

### Proposed production design

**Body, age and silhouette:** 35–45; 173 cm; elegant, grounded build, 7.5 heads. Tall column silhouette from long pleated linen; broad collar makes a controlled shoulder arc. Calm symmetry distinguishes her from Nefru’s mobile archery stance.

**Face and hair:** Painting establishes a composed face, pronounced brows, dark eyes and warm brown skin. Preserve canonical priestess identity. Proposed black hair beneath a white linen head covering; controlled gaze, no default smile. Kohl is subtle around the eye rim.

**Costume and source reconciliation:** White pleated linen gown, golden broad collar and white head covering with restrained ceremonial band, matching the painting. Proposed sandals and a narrow waist fastening hidden by drape. A ritual outfit is the primary costume; no unsupported battle armor.

**Palette and surface materials:** Ivory linen #E9DEC8, gold #BD963F, turquoise #3F8D91 and warm red inset #A85B39. Pleats are soft, close spaced and vertical. Collar is rigid segmented jewelry; stone/enamel accents are smoother than cloth.

**Weapons, props and mount:** Sistrum of Karnak: handle, loop frame and separate metal rods/rattles, all visible in a detail drawing. Archer-class leadership does not require replacing her sistrum with a bow. An optional auxiliary bow is a variant proposal only.

**3D construction and animation:** Gown needs leg clearance and cloth simulation or skirt bones; pleats bake into normals except silhouette folds. Collar must avoid neck clipping. Sistrum rods can animate subtly. Actions: marking gesture for Eye of Horus, ritual lift and measured council turn.

**Required turnaround details:** Full-length sheet must show feet and gown hem. Detail collar layers, headdress rear fastening and sistrum parts. Keep incense/background out of the modeling orthographics.

**Reusable concept prompt:**

> Create a full-body production character sheet of Meritamun from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: an Egyptian high priestess in white pleated linen and a golden broad collar, a sistrum in one hand, temple columns and incense smoke behind her; signature item: Sistrum of Karnak. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Arsamis — The Persian Strategist

**Asset ID:** `arsames` · **Empire:** Persia · **Class:** rider · **Rarity:** epic

**Canonical appearance:** a Persian satrap in a purple and gold riding coat and tall cap, gold torque, astride a Nisaean horse before mountain passes.

**Canonical signature / skill:** Golden Rhyton of Tribute / Satrap's Levy. Calls reinforcements mid-battle, restoring riders to the formation.

**Character anchor:** Forged in the borderlands where Persia, Rome, trade routes and rival kingdoms collided, Arsamis mastered cavalry, diplomacy and supply, and fought beside Rome when Persia's interests aligned with it. Watching villages stripped and prisoners marched while rulers bargained far away, he became one of the four founders, the one who knows yesterday's enemy may be tomorrow's ally.

**Historical status:** The name recalls Arsames, a real Achaemenid noble and grandfather of Darius I. This borderland strategist is Aetheria fiction.

**Existing visual reference:** `src/assets/heroes/arsames.webp`.

### Proposed production design

**Body, age and silhouette:** 38–46; 183 cm; robust cavalry diplomat, 7.5 heads. Tall cap and long riding coat form a vertical silhouette; slightly open posture suggests negotiation rather than rigid command.

**Face and hair:** Painting establishes dark beard, thick brows, olive complexion and a welcoming, knowing smile. Keep cap-mounted hair mostly concealed. Proposed dark brown eyes and a few restrained age lines; individuality comes from expression and beard shape.

**Costume and source reconciliation:** Purple and gold riding coat, tall decorated cap and gold torque. Preserve the portrait’s embroidered borders and layered collar. Proposed split skirt, riding trousers, ankle boots and a practical belt beneath decorative layers.

**Palette and surface materials:** Royal purple #613365, antique gold #BC954B, plum cloth #492C46 and leather #59402C. Silk highlights are broad and soft; embroidery has relief without becoming heavy plate armor. Dust and wear sit low on coat and boots.

**Weapons, props and mount:** Golden Rhyton of Tribute: distinct drinking vessel, proposed animal-ended shape stored in a padded saddle case. Nisaean horse is canonical; dark bay coat and restrained harness are proposed. Optional cavalry spear remains a loadout decision.

**3D construction and animation:** Coat tails must part over saddle; cap requires stable head attachment. Torque rigid around collar. Rhyton has separate hand and storage poses. Actions: reinforcement signal, diplomatic open palm, controlled mounted turn.

**Required turnaround details:** Show cap all sides, coat embroidery map, torque section, rhyton and storage case, mounted silhouette and saddle contact. Display name Arsamis; stable source/asset ID arsames.

**Reusable concept prompt:**

> Create a full-body production character sheet of Arsamis from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a Persian satrap in a purple and gold riding coat and tall cap, gold torque, astride a Nisaean horse before mountain passes; signature item: Golden Rhyton of Tribute. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Livia Drusilla — Voice of Rome

**Asset ID:** `livia` · **Empire:** Rome · **Class:** guardian · **Rarity:** legendary

**Canonical appearance:** a Roman noblewoman in a white stola with a golden laurel wreath, composed and commanding.

**Canonical signature / skill:** Laurel of Concord / Imperial Resolve. Shields the weakest ally and strengthens infantry.

**Character anchor:** At the heart of the new imperial household, she has outlasted rivals by seeing three moves ahead and letting others take the credit.

**Historical status:** Livia Drusilla (58 BC to AD 29) was the wife of Augustus and mother of Tiberius. Her counsel in Aetheria and her words here are fiction.

**Existing visual reference:** `src/assets/heroes/founders-atlas.jpg`.

### Proposed production design

**Body, age and silhouette:** 45–55; 169 cm; balanced mature build, 7.5 heads. Quiet upright posture, economical hands and a sweeping draped silhouette. Height and age are artistic selections for a consistent Aetheria depiction.

**Face and hair:** Atlas establishes an oval face, composed dark eyes and intricately arranged dark hair. Preserve that likeness and add subtle maturity rather than a youthful glamour face. Proposed warm light-olive complexion; controlled mouth and direct assessing gaze.

**Costume and source reconciliation:** Catalog requires a white stola and gold laurel; atlas shows red cloak and armor-like upper details. Master design uses white stola with a deep-red palla, golden laurel and restrained brooch. Treat any armored version as a separate explicit variant.

**Palette and surface materials:** Ivory #E6DCC8, Roman red #84302D, muted gold #BA964B, dark hair #30231F. Linen is matte, palla slightly heavier, jewelry polished locally. Cleanly maintained clothing, with minimal battle wear.

**Weapons, props and mount:** Laurel of Concord is the canonical head ornament. Proposed scroll and discreet document case for council poses. Guardian class and Imperial Resolve describe support leadership; a shield or sword is not required by source canon.

**3D construction and animation:** Drapery requires shoulder pins, layered cloth and arm clearance. Laurel is a separate rigid piece; hair is grouped into sculpted braids/coils. Actions: precise counsel, raised protective palm, small authoritative nod.

**Required turnaround details:** Show hairstyle rear construction, wreath closure, stola/palla layering and brooch placement. Include face-neutral orthographics and a council expression sheet; keep drape identical across 2D and 3D.

**Reusable concept prompt:**

> Create a full-body production character sheet of Livia Drusilla from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a Roman noblewoman in a white stola with a golden laurel wreath, composed and commanding; signature item: Laurel of Concord. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Nefru — The Daughter of Kush

**Asset ID:** `nefru` · **Empire:** Egypt · **Class:** archer · **Rarity:** legendary

**Canonical appearance:** an Egyptian royal archer with a golden bow and a blue and gold headdress.

**Canonical signature / skill:** Solar Bow of Ra / Sunlit Volley. Strikes every enemy and improves gathering speed.

**Character anchor:** Born of a Kushite royal line that remembered when Nubian kings ruled Egypt, Nefru refused to be a symbol and became a battlefield commander fiercely protective of the southern peoples. She became one of the four founders because her people deserved rulers who remembered whom power was meant to serve.

**Historical status:** An original Aetheria character.

**Existing visual reference:** `src/assets/heroes/founders-atlas.jpg`.

### Proposed production design

**Body, age and silhouette:** 28–38; 178 cm; athletic royal archer with strong shoulders and back, 7.5 heads. Bow and blue-gold headcloth create two distinctive arcs. Active, grounded stance communicates battlefield command.

**Face and hair:** Atlas establishes deep brown skin, strong cheekbones, dark eyes and black hair beneath a blue-gold headdress. Preserve her Kushite heritage and existing likeness. Expression proud and protective; avoid substituting a generic pale Egyptian royal face.

**Costume and source reconciliation:** Blue-gold headdress and golden bow are canonical. Atlas suggests white linen and a rich broad collar. Proposed battle-ready wrap tunic/skirt with side slit, leather archery bracer, narrow belt and sandals; headdress tails stay short enough to shoot.

**Palette and surface materials:** Lapis blue #244D78, gold #C29B45, white linen #E2D8C0 and leather #65442B. Gold ornament is localized, with matte grip wrap on bow. Cloth has modest road wear; jewelry remains legible rather than uniformly encrusted.

**Weapons, props and mount:** Solar Bow of Ra: gold-faced composite bow with structurally believable limbs and wrapped grip; not a heavy solid-gold bar. Proposed hip quiver and separate arrows. Sunlit Volley can add temporary light VFX; glowing skin and permanent magical eyes are not canon.

**3D construction and animation:** Bowstring controls, arrow sockets and scapula movement are essential. Headdress tails and skirt require controlled secondary motion. Actions: draw/release, broad volley command and protective council stance. Handedness proposed as right-hand draw.

**Required turnaround details:** Front/side/back sheets show full headdress tail lengths, hair exposure, bow grip and bracer. Include full draw pose and bow limb section. Rear clothing and footwear are newly proposed.

**Reusable concept prompt:**

> Create a full-body production character sheet of Nefru from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: an Egyptian royal archer with a golden bow and a blue and gold headdress; signature item: Solar Bow of Ra. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Atossa — The Mother of Persia

**Asset ID:** `atossa` · **Empire:** Persia · **Class:** rider · **Rarity:** legendary

**Canonical appearance:** a Persian queen in riding armour with a jewelled diadem, mounted on a white horse.

**Canonical signature / skill:** Diadem of the Royal Road / Royal Charge. Pierces the rear line and accelerates marches.

**Character anchor:** Daughter of Cyrus the Great, raised in the house that built the Persian Empire, Atossa became a commander who saw the suffering beneath conquest in Egypt, Ionia and Greece. Her soldiers call her the Mother of Persia because she treats villages, soldiers and families as something entrusted to her protection.

**Historical status:** Atossa was a real Achaemenid queen, daughter of Cyrus the Great, wife of Darius I and mother of Xerxes. Aetheria reimagines her as a military commander; her campaigns and words here are fiction.

**Existing visual reference:** `src/assets/heroes/founders-atlas.jpg`.

### Proposed production design

**Body, age and silhouette:** 45–55; 174 cm; strong mature rider, 7.5 heads. Straight-backed but approachable stance. Diadem and cloak frame the head while riding armor keeps the torso compact.

**Face and hair:** Atlas establishes dark eyes, olive skin, black hair under a teal draped head covering and an intent, mature expression. Preserve likeness; proposed fine age lines and tightly controlled hair. Authority comes from attention, not exaggerated scowling.

**Costume and source reconciliation:** Riding armor and jeweled diadem are canonical. Preserve atlas teal head drape and gold scale/embroidered torso. Proposed practical coat over scale armor, split skirt, trousers, boots and a restrained cloak suitable for saddle use.

**Palette and surface materials:** Teal #286D70, antique gold #B18B49, cream #D8C7A5, dark leather #513829. Diadem jewels are small localized accents. Horse is white/very light grey as stated by appearance; keep visible natural shading rather than pure white.

**Weapons, props and mount:** Diadem of the Royal Road is the canonical signature. White mount is canonical. Proposed cavalry spear and sheathed sword support Royal Charge; exact weapons, horse name and tack motifs are not specified. Tack should communicate care rather than excess decoration.

**3D construction and animation:** Separate diadem, head drape, cloak and mount rigs. Cloth should clear reins and shoulder rotation. Actions: mounted charge signal, calming horse touch and attentive council turn. Preserve a readable face when wearing head covering.

**Required turnaround details:** Show diadem front/side/back, jewel arrangement, headcloth folds and riding armor under cloak. Include white horse, saddle, harness routing and mounted leg clearance.

**Reusable concept prompt:**

> Create a full-body production character sheet of Atossa from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a Persian queen in riding armour with a jewelled diadem, mounted on a white horse; signature item: Diadem of the Royal Road. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.


## Mei Lin — The Archer of a Thousand Plans

**Asset ID:** `mei_lin` · **Empire:** Han · **Class:** archer · **Rarity:** legendary

**Canonical appearance:** a Han court strategist in layered green silk robes with a jade pendant and a folding fan, a map table with bronze tokens before her.

**Canonical signature / skill:** Jade Tally of Command / Thousand Bolt Stratagem. Commands a crossbow barrage that grows stronger each round.

**Character anchor:** A Han scholar's daughter and superb archer whose plans won campaigns against the Xiongnu, Nanyue and Dayuan while generals took the credit. When one presented her greatest plan to the Emperor as his own, she walked away and founded a kingdom of knowledge whose first law is: give credit where the idea was born.

**Historical status:** An original Aetheria character.

**Existing visual reference:** `src/assets/heroes/mei_lin.webp`.

### Proposed production design

**Body, age and silhouette:** 28–36; 166 cm; slender but trained archer, 7.5 heads. Layered green robes create an A-shaped silhouette; fan makes a compact radial accent. Hands and gaze are precise.

**Face and hair:** Painting establishes light warm East Asian complexion, dark almond-shaped eyes, fine brows and black hair in a high structured bun with pins and jade ornaments. Preserve the calm, knowing expression. No unexplained facial scars or heavy battle makeup.

**Costume and source reconciliation:** Layered green silk robes, jade pendant and folding fan are canonical. Preserve white inner collar and darker green outer robe. Proposed tied waist, narrow sleeves beneath wider outer sleeves, trousers under robe and soft boots. Combat variant may shorten sleeves without changing core colors.

**Palette and surface materials:** Jade green #438B79, deep green #24594F, ivory #E3DAC5, warm wood #926A3E and jade #70A78C. Silk sheen is soft; pendant is translucent stone, not emissive. Embroidery stays restrained so the silhouette survives small sprites.

**Weapons, props and mount:** Jade Tally of Command is separate from the pendant unless deliberately unified in a future design. Show tally halves or marked tablet as a proposed solution; exact construction is not canon. Folding fan and map table with bronze tokens are canon appearance cues. Optional personal bow supports her lore, but crossbow barrage is a command skill.

**3D construction and animation:** Fan needs a pivot rig or open/closed meshes; bun is rigid with small ornament motion. Sleeves must clear hands during pointing and archery. Actions: move map token, numbered plan gesture, fan open and barrage command.

**Required turnaround details:** Show bun rear view, robe overlap/closures, fan open/closed, jade pendant versus command tally, and map token scale. Portrait table is a scene prop and should not hide the full-body modeling sheet.

**Reusable concept prompt:**

> Create a full-body production character sheet of Mei Lin from Aetheria Rising. Preserve the supplied portrait likeness and canonical anchors: a Han court strategist in layered green silk robes with a jade pendant and a folding fan, a map table with bronze tokens before her; signature item: Jade Tally of Command. Apply the proposed costume decisions above. Show front, back, left side and three-quarter views of the same character at identical scale, neutral A-pose, feet fully visible, even studio lighting and a plain neutral background. Include separate head, equipment and material details. No cropping, no perspective in orthographic views, no scenery covering the body, no extra equipment beyond the approved profile. Keep all views consistent. Treat text labels as optional and add accurate labels manually.

## Decisions to lock before sculpting

1. Approve the catalog-first outfit reconciliations for Gaius, Zhao Lin, Marcus, Kepri, Wei Jian and Livia; their current pictures differ from written appearance in meaningful ways.
2. Approve proposed ages, scale, face refinements, unseen garment backs, loadouts and handedness. Keep display names Kepri/Arsamis while retaining IDs khepri/arsames.
3. Select destination engine and camera style before optimizing rigs, LODs, textures or sprite angles. The source game is React/Vite with a Capacitor shell; no existing 3D runtime requirement is established by these briefs.
4. Approve a single hero turnaround and deformation test first, then carry the same style and technical conventions across all 13.

## Acceptance checklist

- All 13 profiles and references accounted for; no player-generated hero mistaken for a fixed catalog entry.
- Face and silhouette match between portrait, turnaround, model and sprite. All four orthographic views describe one coherent outfit.
- Equipment is recognizable, correctly attached and free of hand/body collisions in signature poses.
- Back views, underlayers, closures, feet and accessories are explicitly designed; no hidden modeling gaps remain.
- Materials remain readable at gameplay scale; jewelry and VFX do not replace the hero’s core silhouette.
- Rigs pass shoulder draw, seated hips, moving skirts, beard/collar clearance and mounted contact tests as applicable.
- Exports have documented scale, axes, texture color spaces and animation naming; source files remain editable.
