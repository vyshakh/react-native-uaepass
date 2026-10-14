const {
  withDangerousMod,
  withInfoPlist,
  withPodfileProperties,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

// UAEPassClient 2.x requires iOS 15.
const MIN_IOS_VERSION = '15.0';

const UAEPASS_QUERY_SCHEMES = [
  'uaepass',
  'uaepassqa',
  'uaepassstg',
  'uaepassdev',
];

function isBelowMinIos(version) {
  return parseFloat(version) < parseFloat(MIN_IOS_VERSION);
}

// Path to the vendored UAEPassClient pod relative to ios/, resolved from this
// package's real location so it also works when node_modules is hoisted
// (monorepos) rather than assuming ../node_modules/react-native-uaepass.
function uaePassPodPath(projectRoot) {
  const packageRoot = path.resolve(__dirname, '..');
  const relative = path.relative(
    path.join(projectRoot, 'ios'),
    path.join(packageRoot, 'ios', 'LocalPods', 'UAEPassClient')
  );
  return relative.split(path.sep).join('/');
}

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

function addUaePassPod(podfileContent, podPath, appName) {
  if (podfileContent.includes("pod 'UAEPassClient'")) {
    return podfileContent;
  }

  // Prefer the target named after the app; fall back to the first target
  // (Expo sanitises the name differently across SDK versions).
  const sanitizedName = (appName || '').replace(/[^A-Za-z0-9_]/g, '');
  const namedTarget = new RegExp(
    `^(\\s*target\\s+['"]${sanitizedName}['"]\\s+do[^\\n]*\\n)`,
    'm'
  );
  const anyTarget = /^(\s*target\s+['"][^'"]+['"]\s+do[^\n]*\n)/m;
  const targetRegex =
    sanitizedName && namedTarget.test(podfileContent) ? namedTarget : anyTarget;

  if (!targetRegex.test(podfileContent)) {
    throw new Error(
      '[react-native-uaepass] Could not find an app target in ios/Podfile to add UAEPassClient to.'
    );
  }

  return podfileContent.replace(
    targetRegex,
    `$1  # UAEPass dependencies\n  pod 'UAEPassClient', :path => '${podPath}'\n\n`
  );
}

function raisePodfilePlatform(podfileContent) {
  // Expo templates: `platform :ios, podfile_properties['ios.deploymentTarget'] || '13.4'`
  // Bare templates:  `platform :ios, '13.0'`
  return podfileContent
    .replace(
      /(platform :ios, podfile_properties\['ios\.deploymentTarget'\] \|\| ')([\d.]+)(')/,
      (match, before, version, after) =>
        isBelowMinIos(version) ? `${before}${MIN_IOS_VERSION}${after}` : match
    )
    .replace(/(platform :ios, ')([\d.]+)(')/, (match, before, version, after) =>
      isBelowMinIos(version) ? `${before}${MIN_IOS_VERSION}${after}` : match
    );
}

const withUaePassIos = (config, uaepassConfig = {}) => {
  // --- Modify Podfile ---
  config = withDangerousMod(config, [
    'ios',
    (modConfig) => {
      const { projectRoot } = modConfig.modRequest;
      const podfilePath = path.join(projectRoot, 'ios', 'Podfile');
      const original = fs.readFileSync(podfilePath, 'utf8');

      let podfileContent = addUaePassPod(
        original,
        uaePassPodPath(projectRoot),
        modConfig.name
      );
      podfileContent = raisePodfilePlatform(podfileContent);

      if (podfileContent !== original) {
        fs.writeFileSync(podfilePath, podfileContent, 'utf8');
      }

      return modConfig;
    },
  ]);

  // --- Raise an explicit deployment target that is too low ---
  config = withPodfileProperties(config, (modConfig) => {
    const target = modConfig.modResults['ios.deploymentTarget'];
    if (target && isBelowMinIos(target)) {
      modConfig.modResults['ios.deploymentTarget'] = MIN_IOS_VERSION;
    }
    return modConfig;
  });

  // --- Modify Info.plist ---
  config = withInfoPlist(config, (modConfig) => {
    const urlName = uaepassConfig.uaePassBundleURLName || '';
    const urlScheme = uaepassConfig.uaePassBundleURLScheme || '';

    if (!urlName || !urlScheme) {
      throw new Error(
        'URL name or scheme not defined in app.json or app.config.js (uaePassBundleURLName or uaePassBundleURLScheme)'
      );
    }

    // Put the UAEPass CFBundleURLTypes entry FIRST, moving it there if an
    // earlier prebuild (or another plugin) left it further down: the native
    // UAEPassClient SDK (HandleURLScheme.externalURLSchemeSuccess/Fail) grabs
    // `CFBundleURLTypes[0].CFBundleURLSchemes[0]` to build the callback URL it
    // hands to the UAE PASS app for the app-to-app login flow. If another
    // entry (e.g. from expo-linking) ends up first, the UAE PASS app is told to
    // call back with the wrong scheme and the redirect is silently lost.
    // Filtering out the existing entry also keeps re-runs of `expo prebuild`
    // (without --clean) from appending duplicates.
    const otherURLTypes = (modConfig.modResults.CFBundleURLTypes || []).filter(
      (entry) =>
        entry.CFBundleURLName !== urlName &&
        !(entry.CFBundleURLSchemes || []).includes(urlScheme)
    );

    modConfig.modResults.CFBundleURLTypes = [
      {
        CFBundleTypeRole: 'Editor',
        CFBundleURLName: urlName,
        CFBundleURLSchemes: [urlScheme],
      },
      ...otherURLTypes,
    ];

    // Merge, rather than replace, so other plugins' query schemes survive.
    const querySchemes = modConfig.modResults.LSApplicationQueriesSchemes || [];
    modConfig.modResults.LSApplicationQueriesSchemes = [
      ...querySchemes,
      ...UAEPASS_QUERY_SCHEMES.filter(
        (scheme) => !querySchemes.includes(scheme)
      ),
    ];

    return modConfig;
  });

  // --- Add openURL / continue-userActivity handling to AppDelegate ---
  config = withUaePassAppDelegate(config);

  return config;
};

module.exports = {
  withUaePassIos,
  // exported for tests
  addUaePassPod,
  raisePodfilePlatform,
};
