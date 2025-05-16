package com.uaepass;

import android.content.Context;
import android.content.pm.PackageManager;
import java.io.File;

import ae.sdg.libraryuaepass.business.Environment;
import ae.sdg.libraryuaepass.business.Environment.STAGING;
import ae.sdg.libraryuaepass.business.Environment.PRODUCTION;
import ae.sdg.libraryuaepass.business.authentication.model.UAEPassAccessTokenRequestModel;
import ae.sdg.libraryuaepass.business.profile.model.UAEPassProfileRequestModel;
import ae.sdg.libraryuaepass.business.Language;
import ae.sdg.libraryuaepass.utils.Utils;
import android.net.Uri;
import android.util.Log;

public class UaepassRequestModels {

    public static String UAE_PASS_CLIENT_ID = "";
    public static String UAE_PASS_CLIENT_SECRET = "";
    public static String REDIRECT_URL = "";
    public static String ENV = "staging";
    public static String SCOPE = "urn:uae:digitalid:profile";
    public static final String RESPONSE_TYPE = "code";
    public static final String ACR_VALUES_MOBILE = "urn:digitalid:authentication:flow:mobileondevice";
    public static final String ACR_VALUES_WEB = "urn:safelayer:tws:policies:authentication:level:low";
    public static String UAE_PASS_PACKAGE_ID = "ae.uaepass.mainapp";
    public static String UAE_PASS_STG_PACKAGE_ID = "ae.uaepass.mainapp.stg";
    public static String SCHEME = "";
    public static String SUCCESS_HOST = "";
    public static String FAILURE_HOST = "";
    public static Language LOCALE = Language.EN;
    public static final String STATE = Utils.INSTANCE.generateRandomString(24);
    public static final String TAG = "UAEPass";
    public static String BASE_URL = "";

    public static void setConfig(String env, String uae_pass_client_id, String redirect_url,
            String scope, String scheme, String locale, String success_host, String failure_host) {

        ENV = env;
        UAE_PASS_CLIENT_ID = uae_pass_client_id;
        REDIRECT_URL = redirect_url;
        SCOPE = scope;
        SCHEME = scheme;
        SUCCESS_HOST = success_host;
        FAILURE_HOST = failure_host;

        if (ENV.equals("production")) {
            BASE_URL = "https://id.uaepass.ae";
        } else {
            BASE_URL = "https://stg-id.uaepass.ae";
        }

        if (locale.equals("ar"))
            LOCALE = Language.AR;
    }

    public static boolean isPackageInstalled(PackageManager packageManager) {
        String packageName = null;
        boolean found = true;
        if (ENV.equals("production")) {
            packageName = UAE_PASS_PACKAGE_ID;
        } else {
            packageName = UAE_PASS_STG_PACKAGE_ID;
        }
        try {
            packageManager.getPackageInfo(packageName, 0);
        } catch (PackageManager.NameNotFoundException e) {
            found = false;
        }
        return found;
    }

    private static Environment getEnvironment() {
        if (ENV.equals("production"))
            return PRODUCTION.INSTANCE;
        return STAGING.INSTANCE;
    }

    public static String buildAuthorizationUrl() {
        return BASE_URL + "/idshub/authorize?" +
                "client_id=" + UAE_PASS_CLIENT_ID + "&" +
                "redirect_uri=" + REDIRECT_URL + "&" +
                "response_type=code&" +
                "scope=" + SCOPE + "&" +
                "acr_values=" + ACR_VALUES_WEB + "&" +
                "lang=" + LOCALE;
    }

    public static UAEPassAccessTokenRequestModel getAuthenticationRequestModel(Context context) {

        String ACR_VALUE = "";
        if (isPackageInstalled(context.getPackageManager())) {
            ACR_VALUE = ACR_VALUES_MOBILE;
        } else {
            ACR_VALUE = ACR_VALUES_WEB;
        }

        Environment UAE_PASS_ENVIRONMENT = getEnvironment();

        return new UAEPassAccessTokenRequestModel(
                UAE_PASS_ENVIRONMENT,
                UAE_PASS_CLIENT_ID,
                UAE_PASS_CLIENT_SECRET,
                SCHEME,
                FAILURE_HOST,
                SUCCESS_HOST,
                REDIRECT_URL,
                SCOPE,
                RESPONSE_TYPE,
                ACR_VALUE,
                STATE,
                LOCALE);

    }

    public static UAEPassProfileRequestModel getProfileRequestModel(Context context) {

        String ACR_VALUE = "";
        if (isPackageInstalled(context.getPackageManager())) {
            ACR_VALUE = ACR_VALUES_MOBILE;
        } else {
            ACR_VALUE = ACR_VALUES_WEB;
        }

        Environment UAE_PASS_ENVIRONMENT = getEnvironment();

        return new UAEPassProfileRequestModel(
                UAE_PASS_ENVIRONMENT,
                UAE_PASS_CLIENT_ID,
                UAE_PASS_CLIENT_SECRET,
                SCHEME,
                FAILURE_HOST,
                SUCCESS_HOST,
                REDIRECT_URL,
                SCOPE,
                RESPONSE_TYPE,
                ACR_VALUE,
                STATE,
                LOCALE);
    }

}
