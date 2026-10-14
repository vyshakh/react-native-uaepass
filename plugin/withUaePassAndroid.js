const {
  withAndroidManifest,
  withDangerousMod,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

const LOGIN_ACTIVITY = 'com.uaepass.LoginActivity';

// Directory holding the UAE PASS .aar relative to android/, resolved from this
// package's real location so it also works when node_modules is hoisted
// (monorepos) rather than assuming ../node_modules/react-native-uaepass.
function uaePassLibsPath(projectRoot) {
  const packageRoot = path.resolve(__dirname, '..');
  const relative = path.relative(
    path.join(projectRoot, 'android'),
    path.join(packageRoot, 'android', 'libs')
  );
  return relative.split(path.sep).join('/');
}

function hasUaePassFlatDir(buildGradleContent, libsPath) {
  return (
    buildGradleContent.includes('react-native-uaepass/android/libs') ||
    buildGradleContent.includes(libsPath)
  );
}

function addUaePassFlatDir(buildGradleContent, libsPath) {
  if (hasUaePassFlatDir(buildGradleContent, libsPath)) {
    return buildGradleContent;
  }
  return buildGradleContent.replace(
    /allprojects\s*\{[\s\S]*?repositories\s*\{/,
    (match) => `${match}
        // react-native-uaepass: UAE PASS SDK .aar
        flatDir {
            dirs "\${rootDir}/${libsPath}"
        }`
  );
}

const withUaePassAndroid = (config, uaepassConfig = {}) => {
  // --- Modify AndroidManifest.xml ---
  config = withAndroidManifest(config, (config) => {
    const manifest = config.modResults.manifest;

    // Add <queries> for UAE Pass packages
    if (!manifest.queries) {
      manifest.queries = [];
    }

    const existingPackages = manifest.queries.flatMap(
      (query) => query.package?.map((pkg) => pkg.$['android:name']) || []
    );

    const requiredPackages = ['ae.uaepass.mainapp', 'ae.uaepass.mainapp.stg'];

    // Add only if not already present
    const newPackages = requiredPackages
      .filter((pkg) => !existingPackages.includes(pkg))
      .map((pkg) => ({ $: { 'android:name': pkg } }));

    if (newPackages.length > 0) {
      manifest.queries.push({ package: newPackages });
    }

    // Ensure application array exists
    if (!manifest.application) {
      manifest.application = [{}];
    }

    // Initialize activities array if it doesn't exist
    if (!manifest.application[0].activity) {
      manifest.application[0].activity = [];
    }

    // Add <intent-filter> to .MainActivity
    const mainActivity = manifest.application[0].activity.find(
      (a) => a.$['android:name'] === '.MainActivity'
    );

    if (!mainActivity) {
      throw new Error('MainActivity not found in AndroidManifest.xml');
    }

    if (!mainActivity['intent-filter']) {
      mainActivity['intent-filter'] = [];
    }

    const packageId = uaepassConfig.appPackageId;
    if (!packageId) {
      throw new Error('Android package ID not defined in app.config.js');
    }

    const intentFilters = mainActivity['intent-filter'];
    const alreadyExists = intentFilters.some((filter) => {
      const hasViewAction = filter.action?.some(
        (action) => action.$['android:name'] === 'android.intent.action.VIEW'
      );
      const hasBrowsableCategory = filter.category?.some(
        (cat) => cat.$['android:name'] === 'android.intent.category.BROWSABLE'
      );
      const hasScheme = filter.data?.some(
        (data) => data.$['android:scheme'] === packageId
      );
      return hasViewAction && hasBrowsableCategory && hasScheme;
    });
    if (!alreadyExists) {
      mainActivity['intent-filter'].push({
        action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
        category: [
          { $: { 'android:name': 'android.intent.category.DEFAULT' } },
          { $: { 'android:name': 'android.intent.category.BROWSABLE' } },
        ],
        data: [{ $: { 'android:scheme': packageId } }],
      });
    }

    // Add com.uaepass.LoginActivity, replacing any copy from an earlier
    // prebuild so changed hosts/scheme are picked up.
    const scheme = uaepassConfig.uaePassScheme;
    const hostSuccess = uaepassConfig.uaePassSuccess;
    const hostFailure = uaepassConfig.uaePassFailure;

    if (!scheme || !hostSuccess || !hostFailure) {
      throw new Error(
        'Missing required android config values: uaePassScheme, uaePassSuccess, or uaePassFailure in app.config.js or app.json'
      );
    }

    manifest.application[0].activity = manifest.application[0].activity.filter(
      (a) => a.$['android:name'] !== LOGIN_ACTIVITY
    );
    manifest.application[0].activity.push({
      '$': {
        'android:name': LOGIN_ACTIVITY,
        'android:launchMode': 'singleTask',
        'android:exported': 'true',
        'android:parentActivityName': '.MainActivity',
      },
      'intent-filter': [
        {
          action: [{ $: { 'android:name': 'android.intent.action.VIEW' } }],
          category: [
            { $: { 'android:name': 'android.intent.category.DEFAULT' } },
            { $: { 'android:name': 'android.intent.category.BROWSABLE' } },
          ],
          data: [
            { $: { 'android:host': hostSuccess, 'android:scheme': scheme } },
            { $: { 'android:host': hostFailure, 'android:scheme': scheme } },
          ],
        },
      ],
    });

    return config;
  });

  // --- Modify android/build.gradle ---
  // The library depends on the bundled .aar by name, which Gradle can only
  // resolve through a flatDir repository declared by the app.
  config = withDangerousMod(config, [
    'android',
    (config) => {
      const { projectRoot } = config.modRequest;
      const buildGradlePath = path.join(projectRoot, 'android', 'build.gradle');
      const libsPath = uaePassLibsPath(projectRoot);
      const original = fs.readFileSync(buildGradlePath, 'utf8');
      if (hasUaePassFlatDir(original, libsPath)) {
        return config;
      }

      const updated = addUaePassFlatDir(original, libsPath);
      if (updated === original) {
        throw new Error(
          '[react-native-uaepass] Could not find allprojects { repositories { } } in android/build.gradle to add the UAE PASS flatDir repository.'
        );
      }
      fs.writeFileSync(buildGradlePath, updated, 'utf8');

      return config;
    },
  ]);

  return config;
};

module.exports = {
  withUaePassAndroid,
  // exported for tests
  addUaePassFlatDir,
};
