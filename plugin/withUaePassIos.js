const { withDangerousMod, withInfoPlist  } = require("@expo/config-plugins");
const fs = require("fs");
const path = require("path");

const withUaePassIos = (config,  uaepassConfig = {}) => {
  // --- Modify Podfile ---
  config = withDangerousMod(config, [
    "ios",
    (config) => {
      const podfilePath = path.join(config.modRequest.projectRoot, "ios", "Podfile");
      let podfileContent = fs.readFileSync(podfilePath, "utf8");

      // Get the app name from config and sanitize it (remove spaces)
      const targetName = config.name ? config.name.replace(/\s+/g, "") : null;
      if (!targetName) {
        throw new Error("App name not defined in app.json or app.config.js");
      }

      const uaepassPod = `
  # UAEPass dependencies
  pod 'UAEPassClient', :path => '../node_modules/react-native-uaepass/ios/LocalPods/UAEPassClient'
`;

      // Find the target block dynamically
      const targetRegex = new RegExp(`target\\s+'${targetName}'\\s+do\\s*([\\s\\S]*?)(?=end|$)`, "m");
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
        fs.writeFileSync(podfilePath, podfileContent, "utf8");
      }

      return config;
    },
  ]);

  // --- Modify Info.plist ---
  config = withInfoPlist(config, (config) => {
    // Get URL name and scheme, falling back to android.package or android.scheme
    const urlName = uaepassConfig.uaePassBundleURLName || "";
    const urlScheme = uaepassConfig.uaePassBundleURLScheme || "";

    if (!urlName || !urlScheme) {
      throw new Error(
        "URL name or scheme not defined in app.json or app.config.js (uaePassBundleURLName or uaePassBundleURLScheme)"
      );
    }

    // Add or update CFBundleURLTypes
    config.modResults.CFBundleURLTypes = [
      ...(config.modResults.CFBundleURLTypes || []),
      {
        CFBundleTypeRole: "Editor",
        CFBundleURLName: urlName,
        CFBundleURLSchemes: [urlScheme],
      },
    ];

    // Add LSApplicationQueriesSchemes
    // config.modResults.LSApplicationQueriesSchemes = [
    //   ...(config.modResults.LSApplicationQueriesSchemes || []),
    config.modResults.LSApplicationQueriesSchemes = ["uaepass", "uaepassqa", "uaepassstg", "uaepassdev"];

    return config;
  });

  return config;
};

module.exports = { withUaePassIos };