package com.uaepass;

import android.content.Context;
import android.content.pm.PackageManager;
import android.net.Uri;

import ae.sdg.libraryuaepass.business.AuthType;
import ae.sdg.libraryuaepass.business.Environment;
import ae.sdg.libraryuaepass.business.Environment.STAGING;
import ae.sdg.libraryuaepass.business.Environment.PRODUCTION;
import ae.sdg.libraryuaepass.business.authentication.model.UAEPassAccessTokenRequestModel;
import ae.sdg.libraryuaepass.business.Language;
import ae.sdg.libraryuaepass.utils.Utils;

public class UaepassRequestModels {

    public static String UAE_PASS_CLIENT_ID = "";
    public static String REDIRECT_URL = "";
    public static String ENV = "staging";
    public static String SCOPE = "urn:uae:digitalid:profile";
    public static final String RESPONSE_TYPE = "code";
    public static final String ACR_VALUES_MOBILE = "urn:digitalid:authentication:flow:mobileondevice";
    public static final String ACR_VALUES_WEB = "urn:safelayer:tws:policies:authentication:level:low";
    public static final String UAE_PASS_PACKAGE_ID = "ae.uaepass.mainapp";
    public static final String UAE_PASS_STG_PACKAGE_ID = "ae.uaepass.mainapp.stg";
    public static String SCHEME = "";
    public static String SUCCESS_HOST = "";
    public static String FAILURE_HOST = "";
    public static Language LOCALE = Language.EN;
    // Regenerated for every login so a callback can't be replayed into a later one.
    public static String STATE = "";
    public static final String TAG = "UAEPass";
    public static String BASE_URL = "";
    public static String UI_LOCALE = "en";
    public static Boolean CUSTOM_WEB_VIEW = false;

    public static void setConfig(String env, String uae_pass_client_id, String redirect_url,
            String scope, String scheme, String locale, String success_host, String failure_host,
            Boolean use_android_custom_webview, String state) {

        ENV = env;
        UAE_PASS_CLIENT_ID = uae_pass_client_id;
        REDIRECT_URL = redirect_url;
        SCOPE = scope;
        SCHEME = scheme;
        SUCCESS_HOST = success_host;
        FAILURE_HOST = failure_host;
        CUSTOM_WEB_VIEW = use_android_custom_webview;
        STATE = state != null && !state.isEmpty() ? state : Utils.INSTANCE.generateRandomString(24);

        if (isProduction()) {
            BASE_URL = "https://id.uaepass.ae";
        } else {
            BASE_URL = "https://stg-id.uaepass.ae";
        }

        if ("ar".equals(locale)) {
            LOCALE = Language.AR;
            UI_LOCALE = "ar";
        } else {
            LOCALE = Language.EN;
            UI_LOCALE = "en";
        }
    }

    private static boolean isProduction() {
        return "production".equals(ENV);
    }

    public static boolean isPackageInstalled(PackageManager packageManager) {
        String packageName = isProduction() ? UAE_PASS_PACKAGE_ID : UAE_PASS_STG_PACKAGE_ID;
        try {
            packageManager.getPackageInfo(packageName, 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    private static Environment getEnvironment() {
        if (isProduction())
            return PRODUCTION.INSTANCE;
        return STAGING.INSTANCE;
    }

    public static String buildAuthorizationUrl() {
        return Uri.parse(BASE_URL + "/idshub/authorize").buildUpon()
                .appendQueryParameter("client_id", UAE_PASS_CLIENT_ID)
                .appendQueryParameter("redirect_uri", REDIRECT_URL)
                .appendQueryParameter("response_type", RESPONSE_TYPE)
                .appendQueryParameter("state", STATE)
                .appendQueryParameter("scope", SCOPE)
                .appendQueryParameter("acr_values", ACR_VALUES_WEB)
                .appendQueryParameter("ui_locales", UI_LOCALE)
                .build()
                .toString();
    }

    public static UAEPassAccessTokenRequestModel getAuthenticationRequestModel(Context context) {
        String acrValue = isPackageInstalled(context.getPackageManager()) ? ACR_VALUES_MOBILE : ACR_VALUES_WEB;

        // SDK 2.x dropped the client secret (token exchange belongs on the SP
        // backend) and added authentication type + identifier; PIN and "" are
        // the SDK's own defaults.
        return new UAEPassAccessTokenRequestModel(
                getEnvironment(),
                UAE_PASS_CLIENT_ID,
                SCHEME,
                FAILURE_HOST,
                SUCCESS_HOST,
                REDIRECT_URL,
                SCOPE,
                RESPONSE_TYPE,
                acrValue,
                STATE,
                LOCALE,
                AuthType.PIN,
                "");
    }
}
