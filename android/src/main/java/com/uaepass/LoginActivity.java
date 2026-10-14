package com.uaepass;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ProgressBar;

import androidx.appcompat.app.AppCompatActivity;

import ae.sdg.libraryuaepass.UAEPassAccessCodeCallback;
import ae.sdg.libraryuaepass.UAEPassController;
import ae.sdg.libraryuaepass.business.authentication.model.UAEPassAccessTokenRequestModel;

public class LoginActivity extends AppCompatActivity {

    static final String EXTRA_ACCESS_CODE = "accessCode";
    static final String EXTRA_STATE = "state";
    static final String EXTRA_ERROR = "error";
    static final String EXTRA_ERROR_DESCRIPTION = "error_description";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Config lives in statics; after process death it is gone and there is
        // no pending JS promise to report to anyway.
        if (UaepassRequestModels.UAE_PASS_CLIENT_ID.isEmpty()) {
            setResult(Activity.RESULT_CANCELED);
            finish();
            return;
        }

        if (!UaepassRequestModels.isPackageInstalled(getPackageManager()) && UaepassRequestModels.CUSTOM_WEB_VIEW) {
            handleWebView();
        } else {
            uaeLogin();
        }
    }

    public void uaeLogin() {
        UAEPassAccessTokenRequestModel requestModel = UaepassRequestModels.getAuthenticationRequestModel(this);
        UAEPassController.INSTANCE.getAccessCode(this, requestModel, new UAEPassAccessCodeCallback() {
            @Override
            public void getAccessCode(String accessCode, String state, String error) {
                Intent returnIntent = new Intent();
                if (error != null) {
                    returnIntent.putExtra(EXTRA_ERROR, error);
                    setResult(Activity.RESULT_CANCELED, returnIntent);
                } else {
                    returnIntent.putExtra(EXTRA_ACCESS_CODE, accessCode);
                    returnIntent.putExtra(EXTRA_STATE, state);
                    setResult(Activity.RESULT_OK, returnIntent);
                }
                finish();
            }
        });
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    // The UAE PASS app calls back on <scheme>://<successHost|failureHost>;
    // hand that back to the SDK so it can finish the flow.
    private void handleIntent(Intent intent) {
        if (intent != null && intent.getData() != null) {
            if (UaepassRequestModels.SCHEME.equals(intent.getData().getScheme())) {
                UAEPassController.INSTANCE.resume(intent.getDataString());
            }
        }
    }

    private void clearData() {
        try {
            CookieManager.getInstance().removeAllCookies(null);
            CookieManager.getInstance().flush();
        } catch (Exception ignored) {
        }
    }

    protected void handleWebView() {
        clearData();
        Window window = getWindow();
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        String url = UaepassRequestModels.buildAuthorizationUrl();

        FrameLayout rootLayout = new FrameLayout(this);

        WebView webView = new WebView(this);
        webView.setLayoutParams(new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
        webView.clearCache(true);
        webView.clearHistory();
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        webView.setOverScrollMode(View.OVER_SCROLL_NEVER);
        webView.setScrollContainer(false);
        webView.setScrollBarStyle(View.SCROLLBARS_INSIDE_OVERLAY);
        webView.setOnTouchListener((v, event) -> event.getAction() == MotionEvent.ACTION_MOVE);

        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setSupportZoom(false);

        ProgressBar loader = new ProgressBar(this);
        FrameLayout.LayoutParams loaderParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT);
        loaderParams.gravity = Gravity.CENTER;
        loader.setLayoutParams(loaderParams);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                loader.setVisibility(View.VISIBLE);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                loader.setVisibility(View.GONE);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith(UaepassRequestModels.REDIRECT_URL)) {
                    Uri uri = Uri.parse(url);
                    Intent resultIntent = new Intent();
                    resultIntent.putExtra(EXTRA_ACCESS_CODE, uri.getQueryParameter("code"));
                    resultIntent.putExtra(EXTRA_STATE, uri.getQueryParameter("state"));
                    resultIntent.putExtra(EXTRA_ERROR, uri.getQueryParameter("error"));
                    resultIntent.putExtra(EXTRA_ERROR_DESCRIPTION, uri.getQueryParameter("error_description"));
                    setResult(Activity.RESULT_OK, resultIntent);
                    finish();
                    return true;
                }
                return false;
            }
        });

        webView.loadUrl(url);

        rootLayout.addView(webView);
        rootLayout.addView(loader);
        setContentView(rootLayout);
    }

}
