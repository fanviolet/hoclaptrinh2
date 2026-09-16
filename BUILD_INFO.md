# Build 0.4.0

Godot 4.7.2 / Blender 5.2.1. Android portrait ARM64+x86_64, Gradle source template.
AdmobPlugin v7.0 and Google Mobile Ads 24.9.0, Google test rewarded inventory only.

The active GitHub Actions workflow is the authoritative build recipe. Runtime
smoke tests cover physical stacking, camera smoothing, icons/font, Top 50 ranking,
saving, economy and exactly-once ad rewards. Android smoke tests verify install,
launch, drop input, rendering logs and Ranking/advertising UI screenshots.

Ranking contains explicitly identified sample records plus the local best, not
an online player service. Monetization is not activated. See docs/ADS.md.
