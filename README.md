# HighStack 3D — 0.3.0

Original portrait Android stacking game built with Godot 4.7.2 and Blender 5.2.1.

## Play
Drag across the play area to position a block in X/Z, rotate with the arrow buttons,
and tap DROP. On desktop use A/D/W/S, Q/E and Space. Menus pause the scene.

- 13 original rounded props: crate, book, brick, plank, soda can, barrel, parcel,
  candy arch, tiny chair, rainbow T, staircase, UFO and lucky dice.
- Floating islands, clouds, mascot, three purchasable sky palettes, shadows.
- 120 Hz rigid-body physics, continuous collision detection, compound colliders,
  stable contact detection and height measured from transformed collision shapes.
- Orthographic 3D camera keeps the highest settled tower point at 2/3 of viewport
  height, measured from the top. The incoming block is excluded from that anchor.
- Store uses earned coins, three rescue items, five wooden-block skills and themes.
- Vietnamese/English UI, independent music/SFX levels, shadows, vibration and motion.
- Original 40-second looping music plus nine generated effects; no external samples.
- Casual, local Ranked, and explicit offline Arena bot matches (three difficulties,
  90 seconds). Arena/Ranked do not apply purchased physics boosts.
- Validated local saves, one-time coin banking, one-time Arena win rewards.

Human Arena is deliberately disabled until a server is configured. See
[the provider contract](docs/ARENA_PROTOCOL.md). No real ads, billing or online
leaderboard is presented as connected. This APK is for installation/playtesting;
commercial publishing requires publisher-owned signing and service configuration.

## Reproduce
Run from the repository root with Blender, Python 3, Godot and Android SDK installed:

```text
blender -b --python tools/blender_assets.py
python tools/audio_assets.py
godot --headless --editor --path game --quit
godot --headless --path game -- --smoke
godot --headless --path game --export-debug Android build/HighStack3D-v0.3.0.apk
```

CI performs generation, import, smoke tests, signed ARM64+x86_64 APK export,
APK integrity/signature verification and an Android emulator install/launch test.
The workflow produces the APK, SHA-256, logs and an emulator screenshot. Desktop
preview images can be generated with `godot --path game -- --capture` after creating
`build/`. The preview constructs an illustrative tower; the smoke suite separately
checks real rigid-body falling and settlement.

The CI key is a test signing key generated for that run. A previous APK signed by a
different key must be uninstalled first, which removes its local save. Use a stable
publisher keystore for updateable public releases. Do not commit private keys.

Generated GLBs and WAVs are recreated from the checked-in tools and excluded from
Git. The procedural audio and 3D geometry are original to this project.
