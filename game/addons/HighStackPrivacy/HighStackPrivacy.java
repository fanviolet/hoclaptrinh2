package com.highstackstudio.privacy;

import android.app.Activity;
import android.os.SystemClock;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Collections;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/** UMP determines request eligibility; no app-side consent cache. */
public final class HighStackPrivacy extends GodotPlugin {
    private boolean busy = false;
    private AppOpenAd appOpen;
    private boolean openLoading = false;
    private boolean openShowing = false;
    private long openLoadedAt = 0;
    private int openGeneration = 0;
    private static final long OPEN_MAX_AGE_MS = 4L * 60 * 60 * 1000;
    public HighStackPrivacy(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "HighStackPrivacy"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("consent_finished", Boolean.class, Boolean.class, String.class),
            new SignalInfo("app_open_loaded"),
            new SignalInfo("app_open_failed", Integer.class, String.class),
            new SignalInfo("app_open_closed")));
    }
    private void finish(Activity activity, FormError error) {
        busy = false;
        ConsentInformation info = UserMessagingPlatform.getConsentInformation(activity);
        boolean required = info.getPrivacyOptionsRequirementStatus() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
        emitSignal("consent_finished", info.canRequestAds(), required, error == null ? "" : error.getMessage());
    }
    @UsedByGodot public void request_consent() {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (busy) return;
            busy = true;
            ConsentInformation info = UserMessagingPlatform.getConsentInformation(activity);
            info.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(),
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, error -> finish(activity, error)),
                error -> finish(activity, error));
        });
    }
    @UsedByGodot public void show_privacy_options() {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (busy) return;
            busy = true;
            UserMessagingPlatform.showPrivacyOptionsForm(activity, error -> finish(activity, error));
        });
    }

    @UsedByGodot public void clear_app_open() {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            openGeneration++;
            appOpen = null;
            openLoading = false;
            openLoadedAt = 0;
        });
    }

    @UsedByGodot public void load_app_open(String unitId) {
        Activity activity = getActivity();
        if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (!UserMessagingPlatform.getConsentInformation(activity).canRequestAds() || busy || openShowing || openLoading) return;
            if (appOpen != null && SystemClock.elapsedRealtime()-openLoadedAt < OPEN_MAX_AGE_MS) return;
            appOpen = null;
            openLoading = true;
            int generation = ++openGeneration;
            // Ignore timed-out and privacy-invalidated responses; a late load never displays itself.
            new android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(() -> {
                if (openLoading && generation == openGeneration) {
                    openGeneration++;
                    openLoading = false;
                    emitSignal("app_open_failed", -1, "Load timeout");
                }
            }, 30000);
            AppOpenAd.load(activity, unitId, new AdRequest.Builder().build(), new AppOpenAd.AppOpenAdLoadCallback() {
                @Override public void onAdLoaded(AppOpenAd ad) {
                    if (generation != openGeneration) return;
                    openLoading = false;
                    appOpen = ad;
                    openLoadedAt = SystemClock.elapsedRealtime();
                    emitSignal("app_open_loaded");
                }
                @Override public void onAdFailedToLoad(LoadAdError error) {
                    if (generation != openGeneration) return;
                    openLoading = false;
                    appOpen = null;
                    emitSignal("app_open_failed", error.getCode(), error.getMessage());
                }
            });
        });
    }

    @UsedByGodot public void show_app_open() {
        Activity activity = getActivity();
        if (activity == null) { emitSignal("app_open_closed"); return; }
        activity.runOnUiThread(() -> {
            if (openShowing) return;
            if (busy || !UserMessagingPlatform.getConsentInformation(activity).canRequestAds() || appOpen == null ||
                    SystemClock.elapsedRealtime()-openLoadedAt >= OPEN_MAX_AGE_MS) {
                appOpen = null;
                emitSignal("app_open_closed");
                return;
            }
            AppOpenAd ad = appOpen;
            appOpen = null;
            openShowing = true;
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdDismissedFullScreenContent() {
                    openShowing = false;
                    emitSignal("app_open_closed");
                }
                @Override public void onAdFailedToShowFullScreenContent(AdError error) {
                    openShowing = false;
                    emitSignal("app_open_failed", error.getCode(), error.getMessage());
                    emitSignal("app_open_closed");
                }
            });
            ad.show(activity);
        });
    }
}
