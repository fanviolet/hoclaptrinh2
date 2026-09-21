# Advertising — 0.5.0

Publisher App ID: ca-app-pub-7928274342057259~5038324740
Publisher rewarded ID: ca-app-pub-7928274342057259/8779093357
The user supplied both IDs and confirmed Rewarded format on 2026-09-21.

Native Google Mobile Ads 24.9.0 through AdmobPlugin v7.0. The custom HighStackPrivacy
bridge uses UMP 4.0.0: update on every launch, required form, SDK canRequestAds gate,
and privacy options in Settings. A failure leaves gameplay available and a retry
path. Changing privacy choices invalidates cached ads. No automatic interstitials.
Only the SDK earned callback awards 120 coins; duplicate callbacks grant nothing.

The integration uses direct AdMob. A unit named Facebook does not enable Meta
Audience Network. If this unit was created exclusively for third-party bidding,
the publisher must supply a standard AdMob rewarded unit for direct SDK serving.

Ad fill/revenue cannot be promised by a build. In AdMob the publisher must complete
app readiness and Privacy & messaging configuration, including any required
published consent message and privacy policy. Play publication also needs audience,
ads and data-safety declarations and a stable signing key. None of these account
settings can be inferred from public IDs. No password is needed.

Android emulators are Google test devices; do not click live advertiser content
while testing on a physical device. Google-controlled Test Ad labels remain intact.

References:
- https://developers.google.com/admob/android/privacy
- https://developers.google.com/admob/android/test-ads
- https://play.google.com/store/apps/details?id=com.dinogo.catarmy
