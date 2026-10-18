package com.uaepass;

import android.app.Activity;
import android.content.Intent;
import android.webkit.CookieManager;

import androidx.annotation.NonNull;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.module.annotations.ReactModule;

import ae.sdg.libraryuaepass.UAEPassController;

@ReactModule(name = UaepassModule.NAME)
public class UaepassModule extends ReactContextBaseJavaModule implements ActivityEventListener {

    public static final String NAME = "UAEPass";

    // Error codes shared with iOS (Uaepass.swift) and src/index.tsx.
    static final String ERROR_MISSING_PARAMETERS = "MISSING_PARAMETERS";
    static final String ERROR_CANCELLED = "CANCELLED";
    static final String ERROR_LOGIN_FAILED = "LOGIN_FAILED";
    static final String ERROR_STATE_MISMATCH = "STATE_MISMATCH";
    static final String ERROR_SUPERSEDED = "SUPERSEDED";

    // OAuth `error` values UAE PASS documents as "user cancelled the login"
    // (lower-cased; see docs.uaepass.ae text-message guidelines).
    private static final Set<String> CANCELLATION_ERRORS = new HashSet<>(Arrays.asList(
            "access_denied", "cancelled", "cancelledonapp", "invalid_request", "login_required"));

    // An OAuth error code, as opposed to one of the SDK's own sentences.
    private static final Pattern OAUTH_ERROR = Pattern.compile("^[A-Za-z0-9_.-]+$");

    // Arbitrary, but distinctive enough not to collide with the host app's own codes.
    private static final int LOGIN_REQUEST_CODE = 0x0AE9;

    private Promise promise;

    UaepassModule(ReactApplicationContext context) {
        super(context);
        context.addActivityEventListener(this);
    }

    @Override
    public void onNewIntent(Intent intent) {
    }

    @Override
    @NonNull
    public String getName() {
        return NAME;
    }

    private static String getString(ReadableMap options, String key) {
        if (options.hasKey(key) && options.getType(key) == ReadableType.String) {
            String value = options.getString(key);
            return value == null || value.isEmpty() ? null : value;
        }
        return null;
    }

    private static boolean getBoolean(ReadableMap options, String key, boolean defaultValue) {
        if (options.hasKey(key) && options.getType(key) == ReadableType.Boolean)
            return options.getBoolean(key);
        return defaultValue;
    }

    private void resolvePending(WritableMap result) {
        Promise pending = this.promise;
        this.promise = null;
        if (pending != null) {
            pending.resolve(result);
        }
    }

    private void rejectPending(String code, String message) {
        Promise pending = this.promise;
        this.promise = null;
        if (pending != null) {
            pending.reject(code, message);
        }
    }

    private void rejectPending(String code, String message, WritableMap userInfo) {
        Promise pending = this.promise;
        this.promise = null;
        if (pending != null) {
            pending.reject(code, message, userInfo);
        }
    }

    @ReactMethod
    public void login(ReadableMap options, final Promise promise) {
        String env = getString(options, "env");
        String clientId = getString(options, "clientId");
        String redirectUrl = getString(options, "redirectURL");
        String scope = getString(options, "scope");
        String scheme = getString(options, "scheme");
        String successHost = getString(options, "successHost");
        String failureHost = getString(options, "failureHost");
        // Optional, same as on iOS.
        String locale = getString(options, "locale");
        String state = getString(options, "state");
        boolean useCustomWebView = getBoolean(options, "useAndroidCustomWebView", false);

        if (env == null || clientId == null || redirectUrl == null || scope == null ||
                scheme == null || successHost == null || failureHost == null) {
            promise.reject(ERROR_MISSING_PARAMETERS, "One or more required parameters are missing");
            return;
        }

        Activity currentActivity = getCurrentActivity();
        if (currentActivity == null) {
            promise.reject(ERROR_LOGIN_FAILED, "No current activity to start UAE PASS login from");
            return;
        }

        rejectPending(ERROR_SUPERSEDED, "A newer UAE PASS login replaced this one");
        this.promise = promise;

        try {
            UaepassRequestModels.setConfig(env, clientId, redirectUrl, scope, scheme, locale,
                    successHost, failureHost, useCustomWebView, state);
            Intent loginIntent = new Intent(currentActivity, LoginActivity.class);
            currentActivity.startActivityForResult(loginIntent, LOGIN_REQUEST_CODE);
        } catch (Exception e) {
            rejectPending(ERROR_LOGIN_FAILED, e.getMessage());
        }
    }

    private void clearData() {
        try {
            CookieManager.getInstance().removeAllCookies(null);
            CookieManager.getInstance().flush();
        } catch (Exception ignored) {
        }
    }

    @ReactMethod
    public void logout(final Promise promise) {
        clearData();
        try {
            UAEPassController.INSTANCE.clearAccessToken();
        } catch (Exception ignored) {
        }
        WritableMap map = Arguments.createMap();
        map.putString("message", "Logout successfully");
        promise.resolve(map);
    }

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        if (requestCode != LOGIN_REQUEST_CODE || this.promise == null) {
            return;
        }

        if (data == null) {
            rejectPending(ERROR_CANCELLED, "Authentication Process Canceled By User");
            return;
        }

        String accessCode = data.getStringExtra(LoginActivity.EXTRA_ACCESS_CODE);
        if (resultCode == Activity.RESULT_OK && accessCode != null && !accessCode.isEmpty()) {
            String returnedState = data.getStringExtra(LoginActivity.EXTRA_STATE);
            if (returnedState != null && !returnedState.isEmpty() &&
                    !returnedState.equals(UaepassRequestModels.STATE)) {
                rejectPending(ERROR_STATE_MISMATCH, "UAE PASS returned an unexpected state parameter");
                return;
            }
            WritableMap map = Arguments.createMap();
            map.putString("accessCode", accessCode);
            map.putString("state", UaepassRequestModels.STATE);
            resolvePending(map);
            return;
        }

        String error = data.getStringExtra(LoginActivity.EXTRA_ERROR);
        String description = data.getStringExtra(LoginActivity.EXTRA_ERROR_DESCRIPTION);
        if (error == null || error.isEmpty()) {
            rejectPending(ERROR_LOGIN_FAILED, "Failed to authenticate");
            return;
        }

        // The SDK passes UAE PASS's OAuth `error` (e.g. access_denied,
        // cancelledOnApp) through as-is, but reports its own failures as
        // sentences ("Process canceled by user.", "State mismatch.").
        if (OAUTH_ERROR.matcher(error).matches()) {
            String code = CANCELLATION_ERRORS.contains(error.toLowerCase(Locale.ROOT))
                    ? ERROR_CANCELLED : ERROR_LOGIN_FAILED;
            WritableMap userInfo = Arguments.createMap();
            userInfo.putString("error", error);
            if (description != null && !description.isEmpty()) {
                userInfo.putString("errorDescription", description);
            }
            rejectPending(code, description != null && !description.isEmpty() ? description : error, userInfo);
            return;
        }

        String lower = error.toLowerCase(Locale.ROOT);
        if (lower.contains("state")) {
            rejectPending(ERROR_STATE_MISMATCH, error);
        } else if (lower.contains("cancel")) {
            rejectPending(ERROR_CANCELLED, error);
        } else {
            rejectPending(ERROR_LOGIN_FAILED, error);
        }
    }

}
