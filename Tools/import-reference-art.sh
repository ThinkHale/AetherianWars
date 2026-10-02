#!/bin/sh
# Copies the art and music this game shares with Aetheria Rising into the app
# bundle: hero portraits (the four founders are cut from their shared atlas),
# chronicle paintings for menu backdrops, and the music. Run from the repo
# root; AETHERIA points at a checkout of ThinkHale/aetheria.rising.
set -eu

AETHERIA=${AETHERIA:-"$(cd "$(dirname "$0")/../.." && pwd)/aetheria.rising"}
OUT="App/Resources"
[ -d "$AETHERIA/src/assets" ] || { echo "aetheria.rising not found at $AETHERIA" >&2; exit 1; }

mkdir -p "$OUT/Portraits" "$OUT/Backdrops" "$OUT/Audio"

# Portraits, from the highest-resolution source available.
for hero in arsames bardiya gaius khepri marcus_varro mei_lin meritamun tahmina zhao_lin; do
  src="$AETHERIA/art-inbox/heroes/$hero.png"
  [ -f "$src" ] || src="$AETHERIA/src/assets/heroes/$hero.webp"
  sips -s format jpeg -s formatOptions 82 -Z 1000 "$src" --out "$OUT/Portraits/$hero.jpg" >/dev/null
done

# The founders' atlas: Livia top left, Nefru top right, Wei Jian bottom left,
# Atossa bottom right.
swift "$(dirname "$0")/cut-atlas.swift" "$AETHERIA/src/assets/heroes/founders-atlas.jpg" "$OUT/Portraits"

# Menu backdrops.
for scene in mist-thins legion founding-rome founding-egypt founding-persia founding-han commanders aeterna far-beacon white-wind; do
  sips -s format jpeg -s formatOptions 78 "$AETHERIA/src/assets/chronicle/$scene.webp" --out "$OUT/Backdrops/$scene.jpg" >/dev/null
done

# Music (already loudness-matched AAC).
for track in title march kingdom-rome kingdom-egypt kingdom-persia kingdom-han; do
  cp "$AETHERIA/src/assets/audio/music/$track.m4a" "$OUT/Audio/music-$track.m4a"
done
for sfx in tap empire-chosen reward error; do
  cp "$AETHERIA/src/assets/audio/sfx/$sfx.m4a" "$OUT/Audio/ui-$sfx.m4a"
done

echo "Imported portraits, backdrops and audio from $AETHERIA"
