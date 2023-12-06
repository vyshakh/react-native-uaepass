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

import android.util.Log;

public class UaepassRequestModels {

    private static String UAE_PASS_CLIENT_ID = "";
    private static String UAE_PASS_CLIENT_SECRET = "";
    private static String REDIRECT_URL = "";
    private static String ENV = "staging";
    private static String SCOPE = "urn:uae:digitalid:profile";
    private static final String RESPONSE_TYPE = "code";
    private static final String ACR_VALUES_MOBILE = "urn:digitalid:authentication:flow:mobileondevice";
    private static final String ACR_VALUES_WEB = "urn:safelayer:tws:policies:authentication:level:low";
    private static String UAE_PASS_PACKAGE_ID = "ae.uaepass.mainapp";
    private static String UAE_PASS_STG_PACKAGE_ID = "ae.uaepass.mainapp.stg";
    public static String SCHEME = "";
    private static String SUCCESS_HOST = "";
    private static String FAILURE_HOST = "";
    private static Language LOCALE = Language.EN;
    private static final String STATE = Utils.INSTANCE.generateRandomString(24);
    private static final String TAG = "UAEPass";

    public static void setConfig(String env, String uae_pass_client_id, String redirect_url,
            String scope, String scheme, String locale, String success_host, String failure_host) {

        ENV = env;
        UAE_PASS_CLIENT_ID = uae_pass_client_id;
        REDIRECT_URL = redirect_url;
        SCOPE = scope;
        SCHEME = scheme;
        SUCCESS_HOST = success_host;
        FAILURE_HOST = failure_host;       

        if (locale.equals("ar"))
            LOCALE = Language.AR;
    }

    public static boolean isPackageInstalled(PackageManager packageManager) {
        String packageName = null;
        boolean found = true;
        if (ENV.equals("production")){
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
        return  STAGING.INSTANCE;
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
            LOCALE
        );

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
            LOCALE
        );
    }

}

