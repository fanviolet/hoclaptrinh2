# HighStack 3D — 0.5.0

Godot 4.7.2 / Blender 5.2.1 portrait tower stacking game.

The UI now uses Bungee display lettering and heavy Nunito body text with outlines
and shadows. Store cards show original booster illustrations, quantities, effects,
prices and selectable sky previews. The leaderboard includes a Top 3 podium and
47 rows. Ranked gameplay has been removed; skills and boosters apply to the single
stacking mode. The launcher and splash use original cat-and-tower artwork.

Leaderboard entries remain locally seeded plus a qualifying personal best. The
user requested removal of explanatory prototype copy from the player interface;
this does not create an online leaderboard. Technical limitations live here.

The user's AdMob app and rewarded unit are configured. Native UMP 4.0.0 requests
fresh consent information on launch, presents required forms, and gates ad loading
on canRequestAds. Settings exposes privacy options when UMP requires it. Ads are
opt-in and award 120 coins only once on the earned-reward callback. See docs/ADS.md.

## Build

The existing GitHub Actions workflow generates the 13 Blender models and audio,
imports Godot, executes smoke tests, exports a Gradle Android APK and verifies
signature/install/launch/screenshots on an Android emulator. It packages the custom
UMP bridge through an editor export plugin. ARM64 and x86_64 are included.

Local commands:

```
python tools/ui_assets.py
godot --headless --path game --script ../tools/export_icons.gd
godot --headless --editor --path game --quit
godot --headless --path game -- --smoke
godot --path game -- --capture
```

Model/audio generation requires tools/blender_assets.py and tools/audio_assets.py.
Create build/ before capture. Capture renders an illustrative tower; physics is
verified separately in smoke tests. Controls: drag, rotate, DROP; desktop WASD/QE/Space.
Menus pause physics. The camera eases to settled tower height at a 2/3 screen anchor.

CI generates a new debug signing key per build. Installing over an older APK may
require uninstalling it (deletes its local save). A stable publisher signing key
is still needed for public updateable releases.

## Licenses

Bungee and Nunito: SIL OFL, accompanying license files in game/assets/fonts.
AdmobPlugin v7.0: MIT, bundled license. Original vector illustrations, models and
synthesized audio belong to this project. CatnRobot was a visual reference; its
proprietary font and artwork were not copied.
