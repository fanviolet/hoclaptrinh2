package com.highstackstudio.privacy;

import android.app.Activity;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.Collections;
import java.util.Set;

/** UMP determines request eligibility; no app-side consent cache. */
public final class HighStackPrivacy extends GodotPlugin {
    private boolean busy = false;
    public HighStackPrivacy(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "HighStackPrivacy"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("consent_finished", Boolean.class, Boolean.class, String.class));
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
}
