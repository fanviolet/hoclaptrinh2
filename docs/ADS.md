# Advertising — 0.6.0

| Format | Publisher unit | Placement |
| --- | --- | --- |
| App Open | ca-app-pub-7928274342057259/8668294599 | Eligible foreground entry into lobby |
| Rewarded | ca-app-pub-7928274342057259/4248869130 | Voluntary reward button, +120 currency |

App ID: ca-app-pub-7928274342057259~5038324740. Both screenshot formats are wired
separately. The new Rewarded unit replaces /8779093357, which returned HTTP 403.
No banner,
interstitial or rewarded-interstitial is configured.

Native Google Mobile Ads 24.9.0, AdmobPlugin v7.0 and custom App Open/UMP bridge.
UMP 4.0.0 updates on launch and gates requests through canRequestAds. Privacy
options appear when required. App Open is manually managed; automatic plugin
resume display is disabled. The native cache uses monotonic time, four-hour expiry,
a 30-second request timeout, and generation invalidation for late callbacks.
Foreground eligibility, menu/gameplay exclusion and shared fullscreen cooldown
are handled by the game. Returning from Rewarded/consent does not trigger App Open.
A missed foreground opportunity never causes an ad to appear late inside the app.

App Open is preloaded for warm starts. The first two app launches are ad-free;
a later return after 30 seconds away may show a ready ad while still in the lobby.
Returning to the lobby inside the game does not show App Open. No-ready-ad cold
launches proceed normally. The SDK closes or fails back into the lobby.

Only Rewarded earned callbacks award currency, with duplicate protection.
Load errors are logged with their SDK code/message. No-fill is not a game crash.

## Native QA

CI exports a separate AdsQA APK with Google's official App Open and Rewarded demo
units and demo App ID. It loads both formats, backgrounds the app, verifies App
Open display/dismissal and then opens the rewarded placement. The QA APK bypasses
only the first-two-launch eligibility rule and is not delivered as the game APK.
The production APK retains publisher IDs. See build logs for actual fill results.

## Account-side setup

The 0.5.0 run reported UMP publisher misconfiguration (no published form) and
Rewarded no-fill (code 3). These are checked again for 0.6.0. The publisher must
complete app readiness and Privacy & messaging, including applicable published
forms and a privacy policy. The new Rewarded screenshot provides a direct SDK
unit; the old unit is no longer requested. Meta Audience Network is not enabled.
No publisher password is needed.

References:
- https://developers.google.com/admob/android/app-open?hl=vi
- https://developers.google.com/admob/android/privacy
- https://developers.google.com/admob/android/test-ads
- https://support.google.com/admob/answer/12436136?hl=en
