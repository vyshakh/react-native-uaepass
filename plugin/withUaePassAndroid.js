const {
  withAndroidManifest,
  withDangerousMod,
  withGradleProperties,
} = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

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

    // Add com.uaepass.LoginActivity
    const loginActivityExists = manifest.application[0].activity.some(
      (a) => a.$['android:name'] === 'com.uaepass.LoginActivity'
    );

    if (!loginActivityExists) {
      const scheme = uaepassConfig.uaePassScheme;
      const hostSuccess = uaepassConfig.uaePassSuccess;
      const hostFailure = uaepassConfig.uaePassFailure;

      if (!scheme || !hostSuccess || !hostFailure) {
        throw new Error(
          'Missing required android config values: scheme, uaePassSuccess, or uaePassFailure in app.config.js or app.json'
        );
      }

      manifest.application[0].activity.push({
        '$': {
          'android:name': 'com.uaepass.LoginActivity',
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
    }

    return config;
  });

  // --- Modify android/build.gradle ---
  config = withDangerousMod(config, [
    'android',
    (config) => {
      const buildGradlePath = path.join(
        config.modRequest.projectRoot,
        'android',
        'build.gradle'
      );
      let buildGradleContent = fs.readFileSync(buildGradlePath, 'utf8');

      const flatDir = `flatDir {
    dirs "\${rootDir}/../node_modules/react-native-uaepass/android/libs"
}`;

      // Check if flatDir already exists to avoid duplicates
      if (!buildGradleContent.includes('flatDir')) {
        buildGradleContent = buildGradleContent.replace(
          /allprojects\s*{[\s\S]*?repositories\s*{/,
          `allprojects {
    repositories {
        ${flatDir}`
        );
        fs.writeFileSync(buildGradlePath, buildGradleContent, 'utf8');
      }

      return config;
    },
  ]);

  // --- Modify android/app/build.gradle ---
  config = withDangerousMod(config, [
    'android',
    (config) => {
      const appBuildGradlePath = path.join(
        config.modRequest.projectRoot,
        'android',
        'app',
        'build.gradle'
      );
      let appBuildGradleContent = fs.readFileSync(appBuildGradlePath, 'utf8');

      const packageId = uaepassConfig.appPackageId;
      const appAuthRedirectScheme = uaepassConfig.appAuthRedirectScheme;

      if (!packageId) {
        throw new Error(
          'Android package ID not defined in app.json or app.config.js'
        );
      }

      if (!appAuthRedirectScheme) {
        throw new Error(
          'appAuthRedirectScheme not defined in app.json or app.config.js'
        );
      }

      const manifestPlaceholders = `manifestPlaceholders = [ appAuthRedirectScheme: "${appAuthRedirectScheme}" ]`;

      // Check if manifestPlaceholders already exists
      if (!appBuildGradleContent.includes('manifestPlaceholders')) {
        appBuildGradleContent = appBuildGradleContent.replace(
          /defaultConfig\s*{/,
          `defaultConfig {
    ${manifestPlaceholders}`
        );
      } else {
        appBuildGradleContent = appBuildGradleContent.replace(
          /manifestPlaceholders\s*=\s*\[.*?\]/,
          manifestPlaceholders
        );
      }

      fs.writeFileSync(appBuildGradlePath, appBuildGradleContent, 'utf8');
      return config;
    },
  ]);

  // --- Modify gradle.properties ---
  config = withGradleProperties(config, (config) => {
    let jvmArgsUpdated = false;
    let jetifierUpdated = false;

    config.modResults = config.modResults.map((item) => {
      if (item.key === 'org.gradle.jvmargs') {
        jvmArgsUpdated = true;
        return {
          ...item,
          value: '-Xmx4048m -XX:MaxMetaspaceSize=512m',
        };
      }

      if (item.key === 'android.enableJetifier') {
        jetifierUpdated = true;
        return {
          ...item,
          value: 'true',
        };
      }

      return item;
    });

    // Add org.gradle.jvmargs if it wasn't found
    if (!jvmArgsUpdated) {
      config.modResults.push({
        type: 'property',
        key: 'org.gradle.jvmargs',
        value: '-Xmx4048m -XX:MaxMetaspaceSize=512m',
      });
    }

    // Add android.enableJetifier if it wasn't found
    if (!jetifierUpdated) {
      config.modResults.push({
        type: 'property',
        key: 'android.enableJetifier',
        value: 'true',
      });
    }

    return config;
  });

  return config;
};

module.exports = { withUaePassAndroid };
