# HighStack 3D — 0.6.0

Godot 4.7.2 / Blender 5.2.1 portrait tower stacking game.

A dedicated lobby now starts each session. Results expose one return-to-lobby action;
Settings returns to the same lobby. Returning banks outstanding earnings once,
clears the tower, active body, falling timers, controls, score, combo and camera,
and waits for PLAY. Wallet, purchased items, skills, cosmetics and records persist.
Player-facing currency amounts use the original currency icon instead of coin text.

## Ad formats

App ID: ca-app-pub-7928274342057259~5038324740
App Open: ca-app-pub-7928274342057259/8668294599 (supplied screenshot, 2026-09-29).
Rewarded: ca-app-pub-7928274342057259/4248869130 (new Rewarded screenshot, 2026-09-29).
App Open never grants a reward. Only the explicit Rewarded completion grants 120.
No banner, interstitial or rewarded-interstitial is configured.

App Open is preloaded after UMP and SDK initialization and may show at a warm
foreground entry into the lobby, after at least 30 seconds in the background and
from the third launch onward. It never interrupts a round or menu, never shows
late from a load callback, expires after four hours, and observes a two-minute
cooldown after fullscreen content. Cold launches without a cached ad enter the
lobby directly. Privacy changes invalidate the native App Open cache.

The production APK uses the supplied publisher IDs. CI separately builds an
unshipped AdsQA APK using Google demo units to verify load/show/dismiss flows on
an emulator without exercising live advertising inventory. UMP and ad-fill errors
are recorded separately; SDK integration cannot guarantee account readiness or fill.
See docs/ADS.md.

## Build

The existing GitHub Actions workflow generates 13 Blender models and audio,
imports Godot, executes 104 smoke checks, exports a Gradle Android APK and verifies
signature/install/launch/screenshots on Android. ARM64 and x86_64 are included.

```
python tools/ui_assets.py
godot --headless --path game --script ../tools/export_icons.gd
godot --headless --editor --path game --quit
godot --headless --path game -- --smoke
godot --path game -- --capture
```

Generate model/audio assets with tools/blender_assets.py and tools/audio_assets.py.
Create build/ before capture. Desktop controls: WASD/QE/Space; touch: drag/rotate/drop.
Menus pause physics. The camera eases to settled tower height at a 2/3 screen anchor.
The Top 50 leaderboard remains locally seeded plus a qualifying personal best.

CI generates a debug signing key per build. Installing over an older signed APK
may require uninstalling it (deletes its local save). Public updates need a stable
publisher signing key.

Bungee/Nunito: SIL OFL, licenses bundled. AdmobPlugin v7.0: MIT. Original vector
illustrations, model geometry and synthesized audio belong to this project.
