const {
  withDangerousMod,
  withInfoPlist,
  withAppDelegate,
} = require('@expo/config-plugins');
const { mergeContents } = require('@expo/config-plugins/build/utils/generateCode');
const fs = require('fs');
const path = require('path');

// --- Wire up AppDelegate so UAEPass.handleRedirectUrl actually gets called ---
// Without this, `expo prebuild` never adds an openURL / continue-userActivity
// handler for UAEPass, so the redirect back into the app (in particular the
// app-to-app flow used when the UAE PASS app is installed) is silently dropped.
const withUaePassAppDelegate = (config) => {
  return withAppDelegate(config, (config) => {
    const { language } = config.modResults;

    if (language === 'swift') {
      config.modResults.contents = mergeContents({
        tag: 'react-native-uaepass-import',
        src: config.modResults.contents,
        newSrc: 'import react_native_uaepass',
        anchor: /^import UIKit/,
        offset: 1,
        comment: '//',
      }).contents;

      config.modResults.contents = mergeContents({
        tag: 'react-native-uaepass-open-url',
        src: config.modResults.contents,
        newSrc: `
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let uaepass = UAEPass()
    if uaepass.handleRedirectUrl(url) != nil {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL {
      let uaepass = UAEPass()
      if uaepass.handleRedirectUrl(url) != nil {
        return true
      }
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
`,
        anchor: /class AppDelegate/,
        offset: 1,
        comment: '//',
      }).contents;
    } else if (['objc', 'objcpp'].includes(language)) {
      config.modResults.contents = mergeContents({
        tag: 'react-native-uaepass-import',
        src: config.modResults.contents,
        newSrc: '#import "UAEPass-Swift.h"',
        anchor: /#import "AppDelegate\.h"/,
        offset: 1,
        comment: '//',
      }).contents;

      config.modResults.contents = mergeContents({
        tag: 'react-native-uaepass-open-url',
        src: config.modResults.contents,
        newSrc: `
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
  UAEPass *uaepass = [[UAEPass alloc] init];
  if ([uaepass handleRedirectUrl:url] != nil) {
    return YES;
  }
  return [super application:application openURL:url options:options];
}
`,
        anchor: /@implementation AppDelegate/,
        offset: 1,
        comment: '//',
      }).contents;
    } else {
      throw new Error(
        `react-native-uaepass: cannot wire up AppDelegate because the language "${language}" is not supported.`
      );
    }

    return config;
  });
};

const withUaePassIos = (config, uaepassConfig = {}) => {
  // --- Modify Podfile ---
  config = withDangerousMod(config, [
    'ios',
    (config) => {
      const podfilePath = path.join(
        config.modRequest.projectRoot,
        'ios',
        'Podfile'
      );
      let podfileContent = fs.readFileSync(podfilePath, 'utf8');

      // Get the app name from config and sanitize it (remove spaces)
      const targetName = config.name ? config.name.replace(/\s+/g, '') : null;
      if (!targetName) {
        throw new Error('App name not defined in app.json or app.config.js');
      }

      const uaepassPod = `
  # UAEPass dependencies
  pod 'UAEPassClient', :path => '../node_modules/react-native-uaepass/ios/LocalPods/UAEPassClient'
`;

      // Find the target block dynamically
      const targetRegex = new RegExp(
        `target\\s+'${targetName}'\\s+do\\s*([\\s\\S]*?)(?=end|$)`,
        'm'
      );
      const match = podfileContent.match(targetRegex);

      if (!match) {
        throw new Error(`Target '${targetName}' not found in Podfile`);
      }

      // Check if UAEPassClient pod is already included to avoid duplicates
      if (!podfileContent.includes("pod 'UAEPassClient'")) {
        // Append the UAEPass pod to the target block
        podfileContent = podfileContent.replace(
          targetRegex,
          `target '${targetName}' do
${match[1].trim()}
${uaepassPod}`
        );
        fs.writeFileSync(podfilePath, podfileContent, 'utf8');
      }

      return config;
    },
  ]);

  // --- Modify Info.plist ---
  config = withInfoPlist(config, (config) => {
    // Get URL name and scheme, falling back to android.package or android.scheme
    const urlName = uaepassConfig.uaePassBundleURLName || '';
    const urlScheme = uaepassConfig.uaePassBundleURLScheme || '';

    if (!urlName || !urlScheme) {
      throw new Error(
        'URL name or scheme not defined in app.json or app.config.js (uaePassBundleURLName or uaePassBundleURLScheme)'
      );
    }

    // Add or update CFBundleURLTypes.
    // - Guard against duplicate entries: `expo prebuild` (without --clean) can
    //   run this mod against an already-modified Info.plist, and without this
    //   check the same entry gets appended again on every run.
    // - Put the UAEPass entry FIRST in the array: the native UAEPassClient SDK
    //   (HandleURLScheme.externalURLSchemeSuccess/Fail) grabs
    //   `CFBundleURLTypes[0].CFBundleURLSchemes[0]` to build the callback URL it
    //   hands to the UAE PASS app for the app-to-app login flow. If another
    //   CFBundleURLTypes entry (e.g. from expo-linking or another plugin) ends
    //   up first, the UAE PASS app is told to call back with the wrong scheme
    //   and the redirect into this app is silently lost.
    const existingURLTypes = config.modResults.CFBundleURLTypes || [];
    const alreadyPresent = existingURLTypes.some(
      (entry) =>
        entry.CFBundleURLName === urlName ||
        (entry.CFBundleURLSchemes || []).includes(urlScheme)
    );

    if (!alreadyPresent) {
      config.modResults.CFBundleURLTypes = [
        {
          CFBundleTypeRole: 'Editor',
          CFBundleURLName: urlName,
          CFBundleURLSchemes: [urlScheme],
        },
        ...existingURLTypes,
      ];
    }

    // Add LSApplicationQueriesSchemes
    // config.modResults.LSApplicationQueriesSchemes = [
    //   ...(config.modResults.LSApplicationQueriesSchemes || []),
    config.modResults.LSApplicationQueriesSchemes = [
      'uaepass',
      'uaepassqa',
      'uaepassstg',
      'uaepassdev',
    ];

    return config;
  });

  // --- Add openURL / continue-userActivity handling to AppDelegate ---
  config = withUaePassAppDelegate(config);

  return config;
};

module.exports = { withUaePassIos };
