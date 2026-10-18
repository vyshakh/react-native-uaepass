// Learn more https://docs.expo.dev/guides/monorepos/
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');
const pak = require('../package.json');

const root = path.resolve(__dirname, '..');
const config = getDefaultConfig(__dirname);

const escape = (value) => value.replace(/[|\\{}()[\]^$+*?.]/g, '\\$&');

// The library's source (../src) is bundled directly, but the repo root has its
// own, older react / react-native as devDependencies for jest and tsc. Block
// those so every peer dependency resolves to the single copy in this app.
const peerDependencies = Object.keys(pak.peerDependencies);

config.watchFolders = [...new Set([...(config.watchFolders || []), root])];
config.resolver.blockList = [
  ...[].concat(config.resolver.blockList || []),
  ...peerDependencies.map(
    (name) =>
      new RegExp(`^${escape(path.join(root, 'node_modules', name))}\\/.*$`)
  ),
];
config.resolver.extraNodeModules = {
  ...config.resolver.extraNodeModules,
  // Bundle the library straight from its source.
  [pak.name]: root,
  ...Object.fromEntries(
    peerDependencies.map((name) => [
      name,
      path.join(__dirname, 'node_modules', name),
    ])
  ),
};

module.exports = config;
