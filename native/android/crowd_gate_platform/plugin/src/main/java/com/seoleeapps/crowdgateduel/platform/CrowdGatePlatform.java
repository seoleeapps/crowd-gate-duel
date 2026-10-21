package com.seoleeapps.crowdgateduel.platform;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import androidx.core.content.FileProvider;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.ump.*;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.HashSet;
import java.util.Arrays;
import java.util.Set;

/** Android 경계는 동의, 광고와 시스템 공유만 담당한다. 판정과 노출 시점은 게임이 소유한다. */
public final class CrowdGatePlatform extends GodotPlugin {
    private ConsentInformation consent;
    private InterstitialAd ad;
    private boolean initializing;
    private boolean initialized;
    private boolean showing;
    private int loadGeneration;
    private long loadedAt;

    public CrowdGatePlatform(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "CrowdGatePlatform"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(
            new SignalInfo("consent_updated", Boolean.class, Boolean.class),
            new SignalInfo("interstitial_loaded", Integer.class),
            new SignalInfo("interstitial_load_failed", Integer.class, Integer.class),
            new SignalInfo("interstitial_closed", Integer.class),
            new SignalInfo("interstitial_show_failed", Integer.class, Integer.class),
            new SignalInfo("share_finished", Boolean.class)
        ));
    }
    private void event(String name, Object... values) {
        getGodot().runOnRenderThread(() -> emitSignal(name, values));
    }
    private void onUi(Runnable action) {
        Activity host = getActivity();
        if (host != null) host.runOnUiThread(action);
    }
    @UsedByGodot public void initialize() {
        onUi(() -> {
            Activity host = getActivity();
            consent = UserMessagingPlatform.getConsentInformation(host);
            consent.requestConsentInfoUpdate(host, new ConsentRequestParameters.Builder().build(),
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(host, error -> initializeIfAllowed()),
                error -> initializeIfAllowed());
        });
    }
    private void initializeIfAllowed() {
        boolean required = consent.getPrivacyOptionsRequirementStatus() ==
            ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
        if (!consent.canRequestAds()) {
            ad = null;
            event("consent_updated", false, required);
            return;
        }
        if (initialized) { event("consent_updated", true, required); return; }
        if (initializing) return;
        initializing = true;
        // 대상 연령 13+와 별개로 지역별 IARC 콘텐츠 등급(한국 전체이용가)에 맞춘다.
        MobileAds.setRequestConfiguration(new RequestConfiguration.Builder()
            .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G).build());
        MobileAds.initialize(getActivity(), state -> onUi(() -> {
            initialized = true;
            initializing = false;
            event("consent_updated", consent.canRequestAds(), required);
        }));
    }
    @UsedByGodot public void showPrivacyOptions() {
        onUi(() -> {
            ad = null;
            loadGeneration++;
            UserMessagingPlatform.showPrivacyOptionsForm(getActivity(), error -> initializeIfAllowed());
        });
    }
    @UsedByGodot public void loadInterstitial(String unit, int token) {
        onUi(() -> {
            if (!initialized || consent == null || !consent.canRequestAds() || showing) {
                event("interstitial_load_failed", token, -1);
                return;
            }
            final int generation = ++loadGeneration;
            InterstitialAd.load(getActivity(), unit, new AdRequest.Builder().build(), new InterstitialAdLoadCallback() {
                @Override public void onAdLoaded(InterstitialAd value) {
                    if (generation != loadGeneration || !consent.canRequestAds()) return;
                    ad = value;
                    loadedAt = android.os.SystemClock.elapsedRealtime();
                    event("interstitial_loaded", token);
                }
                @Override public void onAdFailedToLoad(LoadAdError error) {
                    if (generation != loadGeneration) return;
                    ad = null;
                    event("interstitial_load_failed", token, error.getCode());
                }
            });
        });
    }
    @UsedByGodot public void showInterstitial(int token) {
        onUi(() -> {
            InterstitialAd value = ad;
            ad = null;
            Activity host = getActivity();
            if (value == null || showing || !consent.canRequestAds() || host == null || host.isFinishing()
                || android.os.SystemClock.elapsedRealtime() - loadedAt >= 3600000L) {
                event("interstitial_show_failed", token, -1);
                return;
            }
            showing = true;
            value.setFullScreenContentCallback(new FullScreenContentCallback() {
                private boolean completed;
                private void finish(boolean failed, int code) {
                    if (completed) return;
                    completed = true;
                    showing = false;
                    if (failed) event("interstitial_show_failed", token, code);
                    else event("interstitial_closed", token);
                }
                @Override public void onAdDismissedFullScreenContent() { finish(false, 0); }
                @Override public void onAdFailedToShowFullScreenContent(AdError error) { finish(true, error.getCode()); }
            });
            value.show(host);
        });
    }
    @UsedByGodot public void shareImage(String sourcePath) {
        onUi(() -> {
            try {
                Activity host = getActivity();
                File source = new File(sourcePath).getCanonicalFile();
                File allowed = new File(host.getFilesDir(), "share").getCanonicalFile();
                if (!source.getPath().startsWith(allowed.getPath() + File.separator) || !source.isFile()) {
                    event("share_finished", false);
                    return;
                }
                File directory = new File(host.getCacheDir(), "resultcards");
                if (!directory.exists() && !directory.mkdirs()) throw new java.io.IOException();
                File[] previous = directory.listFiles();
                if (previous != null) for (File file : previous) {
                    if (file.lastModified() < System.currentTimeMillis() - 86400000L) file.delete();
                }
                File target = new File(directory, "result-" + System.currentTimeMillis() + ".png");
                try (FileInputStream input = new FileInputStream(source);
                     FileOutputStream output = new FileOutputStream(target)) {
                    byte[] buffer = new byte[8192];
                    int count;
                    while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
                }
                Uri uri = FileProvider.getUriForFile(host, host.getPackageName() + ".resultcards", target);
                Intent intent = new Intent(Intent.ACTION_SEND).setType("image/png")
                    .putExtra(Intent.EXTRA_STREAM, uri).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                intent.setClipData(ClipData.newUri(host.getContentResolver(), "Result card", uri));
                host.startActivity(Intent.createChooser(intent, null));
                event("share_finished", true);
            } catch (Exception error) { event("share_finished", false); }
        });
    }
}
