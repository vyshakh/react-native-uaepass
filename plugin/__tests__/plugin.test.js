const { addUaePassPod, raisePodfilePlatform } = require('../withUaePassIos');
const { addUaePassFlatDir } = require('../withUaePassAndroid');

const EXPO_PODFILE = `require File.join(File.dirname(\`node --print "require.resolve('expo/package.json')"\`), "scripts/autolinking")

platform :ios, podfile_properties['ios.deploymentTarget'] || '13.4'
install! 'cocoapods', :deterministic_uuids => false

target 'MyApp' do
  use_expo_modules!
  config = use_native_modules!

  post_install do |installer|
    react_native_post_install(installer)
  end
end
`;

describe('addUaePassPod', () => {
  it('adds the pod right inside the named target', () => {
    const result = addUaePassPod(
      EXPO_PODFILE,
      '../node_modules/react-native-uaepass/ios/LocalPods/UAEPassClient',
      'My App'
    );
    expect(result).toContain(
      "target 'MyApp' do\n  # UAEPass dependencies\n  pod 'UAEPassClient', :path => '../node_modules/react-native-uaepass/ios/LocalPods/UAEPassClient'\n"
    );
    // The rest of the target block is untouched.
    expect(result).toContain('  post_install do |installer|');
  });

  it('falls back to the first target when the name does not match', () => {
    const result = addUaePassPod(EXPO_PODFILE, 'x', 'Something Else');
    expect(result).toContain("target 'MyApp' do\n  # UAEPass dependencies");
  });

  it('is idempotent', () => {
    const once = addUaePassPod(EXPO_PODFILE, 'x', 'MyApp');
    expect(addUaePassPod(once, 'x', 'MyApp')).toBe(once);
  });
});

describe('raisePodfilePlatform', () => {
  it('raises an Expo default below iOS 15', () => {
    expect(raisePodfilePlatform(EXPO_PODFILE)).toContain(
      "podfile_properties['ios.deploymentTarget'] || '15.0'"
    );
  });

  it('raises a literal platform below iOS 15', () => {
    expect(raisePodfilePlatform("platform :ios, '13.0'\n")).toBe(
      "platform :ios, '15.0'\n"
    );
  });

  it('leaves iOS 15.1 alone', () => {
    const podfile =
      "platform :ios, podfile_properties['ios.deploymentTarget'] || '15.1'\n";
    expect(raisePodfilePlatform(podfile)).toBe(podfile);
  });
});

describe('addUaePassFlatDir', () => {
  const buildGradle = `allprojects {
    repositories {
        google()
        mavenCentral()
        flatDir { dirs "libs" }
    }
}
`;

  it('adds its own flatDir even when another one exists', () => {
    const result = addUaePassFlatDir(
      buildGradle,
      '../node_modules/react-native-uaepass/android/libs'
    );
    expect(result).toContain(
      'dirs "${rootDir}/../node_modules/react-native-uaepass/android/libs"'
    );
    expect(result).toContain('flatDir { dirs "libs" }');
  });

  it('is idempotent', () => {
    const libs = '../node_modules/react-native-uaepass/android/libs';
    const once = addUaePassFlatDir(buildGradle, libs);
    expect(addUaePassFlatDir(once, libs)).toBe(once);
  });
});
