# react-native-uaepass

React-native module for UAE Pass.

UAE PASS is the first secure national digital identity for citizens, residents and visitors in UAE. It empowers individuals to access a wide range of online services across various sectors.

Getting Started
To integrate UAE Pass into your React Native project, please follow the enrollment steps provided on the official UAE Pass website: [UAE Pass](https://uaepass.ae/)

For developers, the UAE Pass developer documentation can be found here: [UAE Pass Developer Documentation](https://docs.uaepass.ae/)

## Installation

Install the library from npm:

```sh
npm install react-native-uaepass
# --- or ---
yarn add react-native-uaepass
```

## Versions

| react-native-uaepass | UAE PASS iOS SDK (UAEPassClient) | UAE PASS Android SDK | Minimum iOS |
| --- | --- | --- | --- |
| 2.x | 2.1 | 2.x (`UAE-PASS-Android-Library-release.aar`) | 15.0 |
| 1.x | 1.5 | 1.x | 13.0 |

Upgrading from 1.x? See [Migrating from 1.x](#migrating-from-1x).

## iOS Setup

UAEPass SDK for iOS requires **iOS 15**, so make sure that your deployment target is >= 15.0 in your iOS project settings. (Do not change it, if target is > 15.0)

![alt text](./screenshots/ios/ios_target.png 'iOS target')

Add **one** of the following to your ios/Podfile above the `use_native_modules!` function and run `pod install` from the ios folder:

```ruby
# UAEPass dependencies — the SDK bundled with this package
pod 'UAEPassClient', :path => '../node_modules/react-native-uaepass/ios/LocalPods/UAEPassClient'

# --- or --- the same SDK from git
# pod 'UAEPassClient', :git => 'https://github.com/vyshakh/react-native-uaepass-utils.git', :branch => 'UAEPassClient_2.1'
```

```ruby
# platform :ios, min_ios_version_supported (Do this change only if your target is < 15.0)
platform :ios, '15.0'
```

install the pod.

```sh
$ (cd ios && pod install)
# --- or ---
$ npx pod-install
```

Add your URL Schemes to info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>uaepassdemoappDS_change_this</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>uaepassdemoappDS_change_this</string>
        </array>
    </dict>
</array>
```

Add UAEPass Application Queries Schemes to <b>info.plist</b>

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>uaepass</string>
    <string>uaepassqa</string>
    <string>uaepassstg</string>
    <string>uaepassdev</string>
</array>
```

Add below code to <b>AppDelegate.mm </b>

```c
#import "UAEPass-Swift.h"
```

```c
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  UAEPass *uaepass = [[UAEPass alloc] init];
  NSNumber *handled = [uaepass handleRedirectUrl:url];
  if (handled != nil) {
    return YES; // handled by UAEPass
  }

  // Other link handler code goes here
  // return [RCTLinkingManager application:application openURL:url options:options];

  return YES;
}
```

If your project using <b>AppDelegate.swift</b>. Add below code.

```c
import react_native_uaepass
```

```c
// Add these function to 'class AppDelegate'

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {

    if handleUAEPassRedirect(url: url) {
      return true
    }

    return RCTLinkingManager.application(app, open: url, options: options)
  }

  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {

    if let url = userActivity.webpageURL, handleUAEPassRedirect(url: url) {
      return true
    }

    return RCTLinkingManager.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  func handleUAEPassRedirect(url: URL) -> Bool {
    let uaepass = UAEPass()
    // nil = not UAEPASS URL
    return uaepass.handleRedirectUrl(url) != nil
  }
```

## Android Setup

```gradle
// Add below code to android/build.gradle file. Paste it above the last line -  "apply plugin..."
  allprojects {
      repositories{
          flatDir{
            dirs "$rootDir/../node_modules/react-native-uaepass/android/libs"
          }
      }
  }
```

```gradle
// Add below code to android/app/build.gradle (defaultConfig) and use your UAE pass scheme
manifestPlaceholders = [
    host_success: "uaePassSuccess",
    host_failure: "uaePassFail",
    scheme : "scheme",
    main_scheme:"com.test"
]
// UAEPass
```

Jetifier and the `appAuthRedirectScheme` placeholder are no longer needed since 2.0 — the SDK no longer depends on AppAuth or the legacy support library.

Add below lines to AndroidManifest.xml (screenshot below)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<queries>
    <package android:name="ae.uaepass.mainapp" />
    <package android:name="ae.uaepass.mainapp.stg" />
</queries>
```

```xml
<!-- //UAE PASS START Adding Custom Scheme and Host -->
<activity android:name="com.uaepass.LoginActivity"  android:launchMode="singleTask" android:exported="true"  >
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:host="${host_success}" android:scheme="${scheme}" />
        <data android:host="${host_failure}" android:scheme="${scheme}" />
    </intent-filter>
</activity>
<!-- //UAE PASS END Adding Custom Scheme and Host -->
```

```xml
<!-- //UAE PASS -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="${main_scheme}"/>
</intent-filter>
<!-- //UAE PASS -->
```

![alt text](./screenshots/android/manifest.png 'manifest')

## Screenshots

#### iOS

![alt text](./screenshots/ios/ios_all.png 'iOS screenshot')

#### Android

![alt text](./screenshots/android/android_all.png 'Android screenshot')

## Usage

```js
import React, { useState } from 'react';
import {
  SafeAreaView,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
} from 'react-native';
import { UAEPass } from 'react-native-uaepass';

import type { UAEPassConfig as Config } from 'react-native-uaepass';

const UAEPassConfig: Config = {
  env: 'staging', // or production // default staging
  clientId: 'clientId',
  redirectURL: 'com.test://uaepass',
  successHost: 'uaePassSuccess',
  failureHost: 'uaePassFail',
  scheme: 'testscheme',
  scope: 'urn:uae:digitalid:profile:general',
  locale: 'en', // or 'ar' — optional, defaults to 'en'
  // state: 'your-own-state', // optional — a random state is generated per login otherwise
  // useAndroidCustomWebView: false, // optional, Android only
};

const App = () => {
  const [userData, setData] = useState(null);
  const login = async () => {
    try {
      const response = await UAEPass.login(UAEPassConfig);
      if (response && response.accessCode) {
        setData(response);
      }
    } catch (e) {
      console.log('error', e);
    }
  };

  const logout = async () => {
    try {
      const response = await UAEPass.logout();
      console.log('response', response);
      setData(null);
    } catch (e) {
      console.log('error', e);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {!userData && (
        <TouchableOpacity onPress={login}>
          <Text style={styles.text}>Login</Text>
        </TouchableOpacity>
      )}
      {userData && (
        <View>
          <Text style={styles.text}>{`${JSON.stringify(
            userData,
            null,
            4
          )}`}</Text>
          <TouchableOpacity style={styles.button} onPress={logout}>
            <Text style={styles.text}>Logout</Text>
          </TouchableOpacity>
        </View>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'gray',
  },
  text: {
    fontSize: 16,
    color: '#fff',
  },
  button: {
    marginTop: 50,
    padding: 10,
    marginVertical: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;
```

### Result and errors

`UAEPass.login()` resolves with `{ accessCode, state }`. Send `accessCode` to **your backend** and exchange it for an access token there (then fetch the user profile from UAE PASS) — the client secret must never be shipped in the app.

It rejects with one of these `code`s (also exported as `UAEPassErrorCode`):

| code | meaning |
| --- | --- |
| `CANCELLED` | The user closed the login screen or cancelled in the UAE PASS app |
| `LOGIN_FAILED` | UAE PASS returned another error, or the page couldn't load (offline); see `message` |
| `MISSING_PARAMETERS` | A required config value is empty |
| `STATE_MISMATCH` | The `state` returned by UAE PASS did not match the one sent |
| `SUPERSEDED` | `login()` was called again before this one finished |

When the failure came from UAE PASS itself, the error's `userInfo` carries exactly what UAE PASS returned, so you can show your own message for each case — for example the ones UAE PASS's [text message guidelines](https://docs.uaepass.ae/guidelines/design-guidelines/text-message-guidelines) require:

| `userInfo` field | value |
| --- | --- |
| `error` | The OAuth `error` as sent by UAE PASS: `access_denied`, `cancelledOnApp`, `invalid_request`, `login_required`, … (UAE PASS documents these four as "user cancelled the login", so they all come with `code: 'CANCELLED'`) |
| `errorDescription` | The OAuth `error_description`, when UAE PASS sent one (iOS, and Android with `useAndroidCustomWebView`) |

`userInfo` is absent when there is nothing from UAE PASS to report — e.g. the user tapped Cancel on the login screen.

```js
import { UAEPass, UAEPassErrorCode, isUAEPassError } from 'react-native-uaepass';

try {
  const { accessCode } = await UAEPass.login(UAEPassConfig);
  await api.post('/auth/uaepass', { code: accessCode });
} catch (e) {
  if (!isUAEPassError(e)) throw e;

  switch (e.userInfo?.error ?? e.code) {
    case 'cancelledOnApp':
    case 'access_denied':
    case UAEPassErrorCode.CANCELLED:
      showMessage(t('uaepass.userCancelled'));
      break;
    default:
      showMessage(t('uaepass.somethingWentWrong'));
  }
}
```

### For Expo Managed Projects

#### 1. Add the plugin to your **app.config.js**

```
    plugins: [
      [
        "react-native-uaepass",
        {
          "uaePassBundleURLName": "com.yourapp.uaepass",
          "uaePassBundleURLScheme": "com.yourapp.uaepass",
          "uaePassScheme": "scheme",
          "uaePassSuccess": "success",
          "uaePassFailure": "failure",
          "appPackageId":"app.packageId"
        }
      ]
    ]
```

The plugin also raises the iOS deployment target to 15.0 when it is lower. `appAuthRedirectScheme` is no longer used and can be removed.

#### 2. Run prebuild:

`npx expo prebuild --clean`

#### 2. Run your app:

```
npx expo run:ios
npx expo run:android
```

## Migrating from 1.x

- **iOS 15 minimum** (UAEPassClient 2.1). Raise `platform :ios` and the Xcode deployment target, then `pod install`. If your Podfile points at `react-native-uaepass-utils` `main`, switch it to the bundled `:path` or the `UAEPassClient_2.1` branch.
- **Android**: `android.enableJetifier` and the `appAuthRedirectScheme` placeholder are no longer required.
- **Error codes** are now the values in the table above (they used to be `ERROR` on iOS and inconsistent on Android). Error `message`s are now populated on Android too, and the raw UAE PASS `error` / `error_description` are available on `error.userInfo` .
- **iOS now honours `scope`**. 1.x always sent `urn:uae:digitalid:profile` on iOS regardless of config — check the scope you pass is the one registered for your client.
- **`locale` is optional on Android** too (was required there, optional on iOS).
- On iOS the login screen is now always presented modally with a Cancel button instead of being pushed onto your app's navigation stack, and completing login no longer pops your navigation stack to the root.
- The result now also includes `state`.

For more detailed usage and examples, refer to the documentation provided in the UAE Pass developer documentation.

#### Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

#### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

#### Acknowledgments

Special thanks to the UAE Pass team for providing a secure and convenient national digital identity solution.

#### Author

Hi there! I'm [Vyshakh Parakkat](https://www.linkedin.com/in/vyshakhparakkat/). My expertise lies in crafting robust solutions using React Native, ReactJS, Kubernetes, Fastlane and Python.

I hope this project helps you to integrate UAE Pass without any hassle. If you have any questions, suggestions, or just want to connect, feel free to reach out.

Happy coding! 🚀

#### Disclaimer:

This project is not affiliated with or endorsed by UAE Pass or the government of the United Arab Emirates. It is an independent open-source project created for the purpose of integrating UAE Pass functionality into React Native applications.

---
