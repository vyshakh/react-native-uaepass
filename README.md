# react-native-uaepass

React-native module for UAE Pass.

UAE PASS is the first secure national digital identity for citizens, residents and visitors in UAE. It empowers individuals to access a wide range of online services across various sectors.

Getting Started
To integrate UAE Pass into your React Native project, please follow the enrollment steps provided on the official UAE Pass website: [UAE Pass](https://uaepass.ae/)

For developers, the UAE Pass developer documentation can be found here: [UAE Pass Developer Documentation](https://uaepass.ae/)

## Installation

Install the library from npm:

```sh
npm install react-native-uaepass
# --- or ---
yarn add react-native-uaepass

# --- or from source---
yarn add file:./../react-native-uaepass_source_folder
```

## iOS Setup

UAEPass SDK for iOS requires iOS 13, so make sure that your deployment target is >= 13.0 in your iOS project settings.

![alt text](./screenshots/ios/ios_target.png 'iOS target')

Add the following to your iOS/Podfile above the `use_native_modules!` function and run `pod install` from the ios folder:

```ruby
# UAEPass dependencies
pod 'UAEPassClient', :path => '../node_modules/react-native-uaepass/ios/LocalPods/UAEPassClient'

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
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{

//  THIS block of code handles the UAE Pass success or failure redirects(links)
    UAEPass * obj = [[UAEPass alloc] init];
    NSString *successHost = [obj getSuccessHost];
    NSString *failureHost = [obj getFailureHost];
    if ([url.absoluteString containsString: successHost]) {
      [obj handleLoginSuccess];
      return YES;
    }else if ([url.absoluteString containsString: failureHost]){
      [obj handleLoginFailure];
      return NO;
    }
  // UAE pass link handler ends here
  // Other link handler code goes here

  return YES;
// return [RCTLinkingManager application:application openURL:url options:options];
}
```

## Android Setup [Coming soon]
Android support will be available soon


## Screenshots

#### iOS

![alt text](./screenshots/ios/ios_all.png 'iOS screenshot')

<!-- #### Android

![alt text](./screenshots/android/android_all.png 'Android screenshot') -->

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

const UAEPassConfig = {
  env: 'staging', // or production // default staging
  clientId: 'clientId',
  redirectURL: 'com.test://uaepass',
  successHost: 'uaePassSuccess',
  failureHost: 'uaePassFailure',
  scheme: 'testscheme',
  scope: 'urn:uae:digitalid:profile',
  locale: 'en',
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
        <TouchableOpacity
          onPress={login}
        >
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
    color: '#fff'
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

For more detailed usage and examples, refer to the documentation provided in the UAE Pass developer documentation.

#### Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

#### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

#### Acknowledgments

Special thanks to the UAE Pass team for providing a secure and convenient national digital identity solution.

#### Author

Hi there! I'm [Vyshakh Parakkat](https://www.linkedin.com/in/vyshakhparakkat/) a passionate mobile developer with a diverse skill set. My expertise lies in crafting robust solutions using React Native, ReactJS, Kubernetes, Fastlane and Python.

I hope this project helps you to integrate UAE Pass without hassle. If you have any questions, suggestions, or just want to connect, feel free to reach out.

Happy coding! 🚀


#### Disclaimer:

This project is not affiliated with or endorsed by UAE Pass or the government of the United Arab Emirates. It is an independent open-source project created for the purpose of integrating UAE Pass functionality into React Native applications.

---
