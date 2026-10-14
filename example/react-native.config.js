const path = require('path');
const pak = require('../package.json');

// Autolink the library from the repo root. It can't be an npm dependency of
// this app: Yarn won't symlink a package into its own subdirectory.
module.exports = {
  dependencies: {
    [pak.name]: {
      root: path.join(__dirname, '..'),
      platforms: {
        ios: {},
        android: {},
      },
    },
  },
};
