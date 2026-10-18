import type { ExpoConfig } from 'expo/config';

// Expo CLI loads .env before evaluating this file, so the same values drive
// both the native config (via the library's config plugin) and the JS login
// call in src/App.tsx. Copy .env.sample to .env and fill in your client.
const scheme = process.env.EXPO_PUBLIC_UAEPASS_SCHEME || 'testscheme';
const packageId = 'com.uaepassexample';

const config: ExpoConfig = {
  name: 'UAEPassExample',
  slug: 'react-native-uaepass-example',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'light',
  ios: {
    bundleIdentifier: packageId,
    supportsTablet: true,
  },
  android: {
    package: packageId,
    adaptiveIcon: {
      backgroundColor: '#E6F4FE',
      foregroundImage: './assets/android-icon-foreground.png',
      backgroundImage: './assets/android-icon-background.png',
      monochromeImage: './assets/android-icon-monochrome.png',
    },
    predictiveBackGestureEnabled: false,
  },
  plugins: [
    [
      // The library under development (repo root) rather than an npm copy.
      '../app.plugin.js',
      {
        uaePassBundleURLName: scheme,
        uaePassBundleURLScheme: scheme,
        uaePassScheme: scheme,
        uaePassSuccess:
          process.env.EXPO_PUBLIC_UAEPASS_SUCCESS_HOST || 'uaePassSuccess',
        uaePassFailure:
          process.env.EXPO_PUBLIC_UAEPASS_FAILURE_HOST || 'uaePassFail',
        appPackageId: packageId,
      },
    ],
  ],
};

export default config;
