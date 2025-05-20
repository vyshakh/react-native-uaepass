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

        FrameLayout overlay = new FrameLayout(this);
        overlay.setBackgroundColor(Color.parseColor("#80FFFFFF"));

        // Modal Container (fixed size, centered)
        FrameLayout modalContainer = new FrameLayout(this);
        FrameLayout.LayoutParams modalParams = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT);
        modalParams.setMargins(40, 40, 40, 40); // padding to create modal effect
        modalContainer.setLayoutParams(modalParams);
        modalContainer.setBackgroundColor(Color.WHITE);
        modalContainer.setElevation(10f);

        WebView webView = new WebView(this);
        webView.clearCache(true);
        webView.clearHistory();
        webView.setVerticalScrollBarEnabled(false);
        webView.setHorizontalScrollBarEnabled(false);
        // This will prevent touch-based scrolling entirely.
        webView.setOnTouchListener((v, event) -> event.getAction() == MotionEvent.ACTION_MOVE);
        
        // Set WebView settings
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setSupportZoom(false);
        
        // Set Chrome-like User-Agent
        String chromeUserAgent = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36";
        settings.setUserAgentString(chromeUserAgent);
        
        webView.setWebViewClient(new WebViewClient());
        
        // Load the URL
        webView.loadUrl(url);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                if (url.startsWith(UaepassRequestModels.REDIRECT_URL)) {
                    // Parse the code and close WebView
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

        modalContainer.addView(webView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));

        // Close Button
        ImageButton close = new ImageButton(this);
        // Use a built-in white "X" icon or your own drawable
        close.setImageResource(android.R.drawable.ic_menu_close_clear_cancel);
        close.setColorFilter(Color.WHITE);
        GradientDrawable background = new GradientDrawable();
        background.setColor(Color.GRAY);
        background.setShape(GradientDrawable.OVAL); // make it circular
        background.setCornerRadius(100f); // high corner radius to ensure rounded
        close.setBackground(background);
        // Set padding and size
        int size = 40;
        FrameLayout.LayoutParams closeParams = new FrameLayout.LayoutParams(size, size);
        closeParams.gravity = Gravity.END | Gravity.TOP;
        closeParams.setMargins(6, 6, 6, 6);
        close.setLayoutParams(closeParams);
        // Add click listener
        close.setOnClickListener(v -> finish());
        // Add views in correct order
        close.bringToFront();
        overlay.addView(modalContainer);
        overlay.addView(close, closeParams);
        setContentView(overlay);
    }
}
