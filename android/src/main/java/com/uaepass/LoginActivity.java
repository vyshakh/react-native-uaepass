package com.uaepass;

import androidx.appcompat.app.AppCompatActivity;
import android.content.pm.PackageManager;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import ae.sdg.libraryuaepass.UAEPassController;
import ae.sdg.libraryuaepass.business.authentication.model.UAEPassAccessTokenRequestModel;
import ae.sdg.libraryuaepass.business.profile.model.UAEPassProfileRequestModel;
import ae.sdg.libraryuaepass.UAEPassAccessCodeCallback;
import ae.sdg.libraryuaepass.UAEPassAccessTokenCallback;
import ae.sdg.libraryuaepass.UAEPassProfileCallback;
import ae.sdg.libraryuaepass.business.profile.model.ProfileModel;

import android.util.Log;

public class LoginActivity extends AppCompatActivity {

    private static final String TAG = "UAEPass";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        uaeLogin();
    }

    public void uaeLogin() {
        UAEPassAccessTokenRequestModel requestModel = UaepassRequestModels.getAuthenticationRequestModel(this);
        UAEPassController.INSTANCE.getAccessCode(this, requestModel, new UAEPassAccessCodeCallback() {
            @Override
            public void getAccessCode(String accessCode, String error) {
                if (error != null) {
                    Intent returnIntent = new Intent();
                    returnIntent.putExtra("error",error);
                    setResult(Activity.RESULT_CANCELED, returnIntent);
                    finish();
                } else {
                    // login(requestModel, accessCode);
                    Intent returnIntent = new Intent();
                    returnIntent.putExtra("accessCode",accessCode);
                    setResult(Activity.RESULT_OK,returnIntent);
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

}