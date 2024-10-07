package com.uaepass;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import java.util.Map;
import java.util.HashMap;
import androidx.annotation.NonNull;
import com.facebook.react.module.annotations.ReactModule;

import android.os.Build;
import android.app.Activity;
import android.content.Intent;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import androidx.browser.customtabs.TrustedWebUtils;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.Promise;

import android.util.Log;

@ReactModule(name = UaepassModule.NAME)
public class UaepassModule extends ReactContextBaseJavaModule implements ActivityEventListener {

    private Promise promise;
    private static final String TAG = "UAEPass";
    public static final String NAME = "UAEPass";

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

    public String getString(ReadableMap options, String key, String defaultValue) {
        if (options.hasKey(key))
            return options.getString(key);
        return defaultValue;
    }

    public Boolean getBoolean(ReadableMap options, String key, Boolean defaultValue) {
        if (options.hasKey(key))
            return options.getBoolean(key);
        return defaultValue;
    }

    @ReactMethod
    public void login(ReadableMap options, final Promise promise) {
        try {
            this.promise = promise;

            String env = getString(options, "env", null);
            String uae_pass_client_id = getString(options, "clientId", null);
            String redirect_url = getString(options, "redirectURL", null);
            String scope = getString(options, "scope", null);
            String scheme = getString(options, "scheme", null);
            String locale = getString(options, "locale", null);
            String success_host = getString(options, "successHost", null);
            String failure_host = getString(options, "failureHost", null);

            if (uae_pass_client_id == null || redirect_url == null ||
                    scope == null ||
                    scheme == null ||
                    locale == null ||
                    env == null ||
                    success_host == null ||
                    failure_host == null

            ) {
                promise.reject("One or more required parameters are missing");
                return;
            }

            UaepassRequestModels.setConfig(env, uae_pass_client_id, redirect_url, scope, scheme, locale, success_host,
                    failure_host);

            // Start a new activity for uaepass login activity
            Activity currentActivity = getCurrentActivity();
            Intent loginIntent = new Intent(currentActivity, LoginActivity.class);
            loginIntent.putExtra(TrustedWebUtils.EXTRA_LAUNCH_AS_TRUSTED_WEB_ACTIVITY, true);
            currentActivity.startActivityForResult(loginIntent, 5);

        } catch (Exception e) {
            // Log.d(TAG, e.getMessage());
            promise.reject("Failed to authenticate", e.getMessage());
        }
    }

    private void clearData() {
        try{
            CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
                @Override
                public void onReceiveValue(Boolean value) {
                }
            });
            CookieManager.getInstance().flush();
        } catch (Exception e) {}
    }

    @ReactMethod
    public void logout(final Promise promise) {
        clearData();
        WritableMap map = Arguments.createMap();
        map.putString("message", "Logout successfully");
        promise.resolve(map);
    }

    /*
     * Called when the activity completes
     */
    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        try{
            if (requestCode == 5 && this.promise != null) {
                if (data == null) {
                    this.promise.reject("Failed to authenticate", "Data intent is null");
                    return;
                }

                if (resultCode == Activity.RESULT_OK) {
                    WritableMap map = Arguments.createMap();
                    WritableMap profile = Arguments.createMap();
                    map.putString("accessCode", data.getStringExtra("accessCode"));
                    this.promise.resolve(map);
                }
                if (resultCode == Activity.RESULT_CANCELED) {
                    this.promise.reject(data.getStringExtra("error"));
                }
            }
        } catch (Exception e) {}
    }

}
