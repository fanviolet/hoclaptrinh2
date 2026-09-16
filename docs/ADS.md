# Advertising integration

This build is TEST ONLY. The user has not created an AdMob account.

- Native Google Mobile Ads SDK 24.9.0 via godot-sdk-integrations/godot-admob v7.0.
- Demo Android App ID: ca-app-pub-3940256099942544~3347511713
- Demo rewarded unit: ca-app-pub-3940256099942544/5224354917
- Explicit watch button, no forced interstitials or banners during gameplay.
- SDK success callback grants 120 coins once. Early dismissal/load failure does not.
- SDK absence/offline/load timeout presents an unavailable/retry state, never a fake ad.
- These Google test ads generate no publisher revenue. Do not replace only one ID.

## To enable real ads later

The publisher must create AdMob, add the Android app with package
com.highstackstudio.highstack3d, and create a Rewarded ad unit. Provide the App ID
(with ~) and Rewarded Ad Unit ID (with /); passwords and private account credentials
are not needed. Then configure both android_export.cfg and the runtime Admob node
for real IDs, use test-device IDs during validation, and build with a stable signing
key. Before switching to production, implement and configure Google's UMP consent
flow/privacy options, declare the intended audience and appropriate treatment,
provide the privacy policy, and complete the Play Console ads/data-safety entries.
Production mode is deliberately not exposed as an in-game toggle.

References:
- https://developers.google.com/admob/android/test-ads
- https://godot-sdk-integrations.github.io/godot-admob/export.html
- https://godot-sdk-integrations.github.io/godot-admob/usage/user-consent.html

UI inspiration: rounded, legible casual-game typography and compact icon buttons,
referenced against https://play.google.com/store/apps/details?id=com.azurgames.stackball
No proprietary game font or logo was extracted.
