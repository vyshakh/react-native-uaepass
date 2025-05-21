package com.uaepass;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.Window;
import android.webkit.WebView;
import android.webkit.WebSettings;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.ImageView;
import android.graphics.drawable.GradientDrawable;
import android.util.Log;
import android.os.Build;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.view.MotionEvent;
import android.content.Intent;
import androidx.appcompat.app.AppCompatActivity;
import android.content.pm.PackageManager;
import android.view.View;
import android.widget.ProgressBar;
import android.view.Gravity;
import android.graphics.Bitmap;
import ae.sdg.libraryuaepass.UAEPassController;
import ae.sdg.libraryuaepass.business.authentication.model.UAEPassAccessTokenRequestModel;
import ae.sdg.libraryuaepass.UAEPassAccessCodeCallback;

public class LoginActivity extends AppCompatActivity {

    private static final String TAG = "UAEPass";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (UaepassRequestModels.isPackageInstalled(this.getPackageManager())) {
            uaeLogin();
        } else if (UaepassRequestModels.CUSTOM_WEB_VIEW) {
            handleWebView();
        } else {
            uaeLogin();
        }

    }

    public void uaeLogin() {
        UAEPassAccessTokenRequestModel requestModel = UaepassRequestModels.getAuthenticationRequestModel(this);
        UAEPassController.INSTANCE.getAccessCode(this, requestModel, new UAEPassAccessCodeCallback() {
            @Override
            public void getAccessCode(String accessCode, String error) {
                if (error != null) {
                    Intent returnIntent = new Intent();
                    returnIntent.putExtra("error", error);
                    setResult(Activity.RESULT_CANCELED, returnIntent);
                    finish();
                } else {
                    Intent returnIntent = new Intent();
                    returnIntent.putExtra("accessCode", accessCode);
                    setResult(Activity.RESULT_OK, returnIntent);
                    finish();
                }
            }
        });

    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.getData() != null) {
            if (UaepassRequestModels.SCHEME.equals(intent.getData().getScheme())) {
                UAEPassController.INSTANCE.resume(intent.getDataString());
            }
        }
    }

    private void clearData() {
        try {
            CookieManager.getInstance().removeAllCookies(new ValueCallback<Boolean>() {
                @Override
                public void onReceiveValue(Boolean value) {
                }
            });
            CookieManager.getInstance().flush();
        } catch (Exception e) {
        }
    }

    protected void handleWebView() {
        clearData();
        Window window = getWindow();
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
        String url = UaepassRequestModels.buildAuthorizationUrl();
        if (url == null) {
            finish();
            return;
        }

        // Create a parent layout
        FrameLayout rootLayout = new FrameLayout(this);

        // Create WebView
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

        // Set WebView settings
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setSupportZoom(false);

        // Create ProgressBar (spinner)
        ProgressBar loader = new ProgressBar(this);
        FrameLayout.LayoutParams loaderParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT);
        loaderParams.gravity = Gravity.CENTER;
        loader.setLayoutParams(loaderParams);
        // WebViewClient with loader logic
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
                    String code = uri.getQueryParameter("code");
                    String error = uri.getQueryParameter("error");
                    String error_description = uri.getQueryParameter("error_description");
                    Intent resultIntent = new Intent();
                    resultIntent.putExtra("accessCode", code);
                    resultIntent.putExtra("error", error);
                    resultIntent.putExtra("error_description", error_description);
                    setResult(Activity.RESULT_OK, resultIntent);
                    finish();
                    return true;
                }
                return false;
            }
        });

        // Load URL
        webView.loadUrl(url);

        // Add WebView and loader to layout
        rootLayout.addView(webView);
        rootLayout.addView(loader);
        setContentView(rootLayout);
    }

}
