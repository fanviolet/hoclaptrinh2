# HighStack 3D — 0.4.0

Godot 4.7.2 / Blender 5.2.1 portrait stacking game.

## Changes

- Original SVG icons for currency, boosters and menus; function buttons on two side
  rails, with the middle reserved for the tower. Baloo 2 variable font (SIL OFL),
  with Vietnamese glyphs and a rounded casual-game style.
- Camera keeps a fixed horizontal anchor and eases to accepted tower height at
  render-frame cadence, capped at 3 metres/second. Moving collider corners no longer
  drive the camera; after easing, the tower height plane lies at 2/3 of the screen.
  Model scenes are cached before play to reduce loading work at drop/next spawn.
- Arena removed. Ranking shows 50 named sample height records in descending order,
  clearly labelled as sample/offline data. A qualifying local best displaces the
  lowest sample entry. Best height is persisted after every accepted placement.
- Real Google Mobile Ads SDK integration through AdmobPlugin v7.0. This build uses
  only Google's official test App ID and rewarded Ad Unit ID. Ads are opt-in from
  the coin button; 120 coins are awarded only on the SDK earned-reward callback,
  once per ad. Failed loads and early dismissal grant nothing. No banner obscures
  the controls and no interstitial interrupts a drop. See docs/ADS.md.

The 13 Blender props, original audio, physics, Store, settings and local Ranked
mode remain available. Drag to move in X/Z, rotate and tap DROP. Desktop controls:
A/D/W/S, Q/E and Space. Menus pause the game.

## Build and verification

The GitHub Actions workflow generates model/audio assets, imports the project,
executes the integration smoke suite, installs the matching Godot Android Gradle
source template, and exports a signed ARM64+x86_64 debug APK including the native
AdMob AAR and Maven dependencies. Android SDK/network access is required for Gradle.

Local runtime verification:

```text
blender -b --python tools/blender_assets.py
python tools/audio_assets.py
godot --headless --editor --path game --quit
godot --headless --path game -- --smoke
godot --path game -- --capture
```

Create build/ before capture. Capture assembles an illustrative tower; the smoke
suite separately tests real rigid-body falls and settlement, camera continuity,
ranking and the ad reward boundary. CI additionally checks APK signatures and runs
an Android install/launch/touch/render smoke test. Actual ad fill requires internet.

The CI debug signing key is generated per build. To install over an older build
signed with a different key, uninstall the old app first (removes its local save).
A stable publisher signing key is required for public updateable releases.

## Attribution

Baloo 2: Google Fonts / Ek Type, SIL Open Font License in game/assets/fonts/OFL.txt.
AdmobPlugin v7.0: godot-sdk-integrations, MIT license in its addon directory.
Original icons, procedural model geometry and synthesized audio are project assets.
