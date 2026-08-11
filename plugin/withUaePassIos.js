const { withDangerousMod, withInfoPlist } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

// --- Wire up AppDelegate so UAEPass.handleRedirectUrl actually gets called ---
// Without this, `expo prebuild` never adds an openURL / continue-userActivity
// handler for UAEPass, so the redirect back into the app (in particular the
// app-to-app flow used when the UAE PASS app is installed) is silently dropped.
//
// NOTE: this intentionally does NOT use Expo's `withAppDelegate`. That helper
// runs Expo's own `withIosAppDelegateBaseMod` first, which anchors on
// `/^import UIKit/` (or similar) to detect the file — and newer Expo SDK
// AppDelegate.swift templates don't have that import, which crashes prebuild
// for every consumer regardless of what our own mod does. Reading/writing the
// file ourselves via withDangerousMod sidesteps that entirely.
const withUaePassAppDelegate = (config) => {
  return withDangerousMod(config, [
    'ios',
    (modConfig) => {
      const iosRoot = path.join(modConfig.modRequest.projectRoot, 'ios');

      const appDirName = fs
        .readdirSync(iosRoot, { withFileTypes: true })
        .find(
          (entry) =>
            entry.isDirectory() &&
            (fs.existsSync(
              path.join(iosRoot, entry.name, 'AppDelegate.swift')
            ) ||
              fs.existsSync(path.join(iosRoot, entry.name, 'AppDelegate.mm')))
        )?.name;

      if (!appDirName) {
        console.warn(
          '[react-native-uaepass] Could not locate AppDelegate.swift/.mm under ios/. ' +
            'Skipping automatic AppDelegate wiring — add the redirect handler manually, see README.'
        );
        return modConfig;
      }

      const swiftPath = path.join(iosRoot, appDirName, 'AppDelegate.swift');
      const objcPath = path.join(iosRoot, appDirName, 'AppDelegate.mm');

      if (fs.existsSync(swiftPath)) {
        patchSwiftAppDelegate(swiftPath);
      } else if (fs.existsSync(objcPath)) {
        patchObjcAppDelegate(objcPath);
      }

      return modConfig;
    },
  ]);
};

function patchSwiftAppDelegate(appDelegatePath) {
  let contents = fs.readFileSync(appDelegatePath, 'utf8');

  // Idempotent: skip if we've already patched this file (e.g. re-running
  // `expo prebuild` without --clean).
  if (
    contents.includes('handleUAEPassRedirect') ||
    contents.includes('UAEPass()')
  ) {
    return;
  }

  // 1. Import, right after the first import line.
  if (!contents.includes('import react_native_uaepass')) {
    contents = contents.replace(
      /^import .+$/m,
      (firstImportLine) => `${firstImportLine}\nimport react_native_uaepass`
    );
  }

  // 2. Merge into the existing `open url:` override if present, otherwise
  // insert a new override right after the class declaration.
  const openUrlOverrideRegex =
    /(public override func application\(\s*_ app: UIApplication,\s*open url: URL,\s*options: \[UIApplication\.OpenURLOptionsKey: Any\] = \[:\]\s*\) -> Bool \{\s*)/;

  const openUrlHook = `
    let uaepass = UAEPass()
    if uaepass.handleRedirectUrl(url) != nil {
      return true
    }
`;

  if (openUrlOverrideRegex.test(contents)) {
    contents = contents.replace(openUrlOverrideRegex, `$1${openUrlHook}`);
  } else {
    contents = contents.replace(
      /(class AppDelegate: ExpoAppDelegate \{\s*)/,
      `$1
  public override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
${openUrlHook}
    return super.application(app, open: url, options: options)
  }
`
    );
  }

  // 3. Merge into the existing `continue userActivity:` override if present,
  // otherwise insert a new override.
  const continueActivityRegex =
    /(public override func application\(\s*_ application: UIApplication,\s*continue userActivity: NSUserActivity,\s*restorationHandler: @escaping \(\[UIUserActivityRestoring\]\?\) -> Void\s*\) -> Bool \{\s*)/;

  const continueActivityHook = `
    if let url = userActivity.webpageURL {
      let uaepass = UAEPass()
      if uaepass.handleRedirectUrl(url) != nil {
        return true
      }
    }
`;

  if (continueActivityRegex.test(contents)) {
    contents = contents.replace(
      continueActivityRegex,
      `$1${continueActivityHook}`
    );
  } else {
    contents = contents.replace(
      /(class AppDelegate: ExpoAppDelegate \{[\s\S]*?\n\})/,
      (classBlock) =>
        classBlock.replace(
          /\n\}$/,
          `
  public override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
${continueActivityHook}
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}`
        )
    );
  }

  fs.writeFileSync(appDelegatePath, contents, 'utf8');
}

function patchObjcAppDelegate(appDelegatePath) {
  let contents = fs.readFileSync(appDelegatePath, 'utf8');

  if (contents.includes('handleRedirectUrl')) {
    return;
  }

  if (!contents.includes('#import "UAEPass-Swift.h"')) {
    contents = contents.replace(
      /(#import "AppDelegate\.h"\s*)/,
      `$1#import "UAEPass-Swift.h"\n`
    );
  }

  const openUrlRegex =
    /(- \(BOOL\)application:\(UIApplication \*\)application\s+openURL:\(NSURL \*\)url\s+options:\(NSDictionary<UIApplicationOpenURLOptionsKey,id> \*\)options\s*\{\s*)/;

  const openUrlHook = `
  UAEPass *uaepass = [[UAEPass alloc] init];
  if ([uaepass handleRedirectUrl:url] != nil) {
    return YES;
  }
`;

  if (openUrlRegex.test(contents)) {
    contents = contents.replace(openUrlRegex, `$1${openUrlHook}`);
  } else {
    contents = contents.replace(
      /(@implementation AppDelegate\s*)/,
      `$1
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
${openUrlHook}
  return [RCTLinkingManager application:application openURL:url options:options];
}
`
    );
  }

  fs.writeFileSync(appDelegatePath, contents, 'utf8');
}

const withUaePassIos = (config, uaepassConfig = {}) => {
  // --- Modify Podfile ---
  config = withDangerousMod(config, [
    'ios',
    (modConfig) => {
      const podfilePath = path.join(
        modConfig.modRequest.projectRoot,
        'ios',
        'Podfile'
      );
      let podfileContent = fs.readFileSync(podfilePath, 'utf8');

      // Get the app name from config and sanitize it (remove spaces)
      const targetName = modConfig.name
        ? modConfig.name.replace(/\s+/g, '')
        : null;
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

      return modConfig;
    },
  ]);

  // --- Modify Info.plist ---
  config = withInfoPlist(config, (modConfig) => {
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
    const existingURLTypes = modConfig.modResults.CFBundleURLTypes || [];
    const alreadyPresent = existingURLTypes.some(
      (entry) =>
        entry.CFBundleURLName === urlName ||
        (entry.CFBundleURLSchemes || []).includes(urlScheme)
    );

    if (!alreadyPresent) {
      modConfig.modResults.CFBundleURLTypes = [
        {
          CFBundleTypeRole: 'Editor',
          CFBundleURLName: urlName,
          CFBundleURLSchemes: [urlScheme],
        },
        ...existingURLTypes,
      ];
    }

    // Add LSApplicationQueriesSchemes
    modConfig.modResults.LSApplicationQueriesSchemes = [
      'uaepass',
      'uaepassqa',
      'uaepassstg',
      'uaepassdev',
    ];

    return modConfig;
  });

  // --- Add openURL / continue-userActivity handling to AppDelegate ---
  config = withUaePassAppDelegate(config);

  return config;
};

module.exports = { withUaePassIos };
