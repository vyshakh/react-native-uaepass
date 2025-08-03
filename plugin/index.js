const { createRunOncePlugin } = require("@expo/config-plugins");
const { withUaePassIos } = require('./withUaePassIos');
const { withUaePassAndroid } = require('./withUaePassAndroid');

const withUaePass = (config, props = {}) => {
  // Apply iOS configurations
  config = withUaePassIos(config, props);
  
  // Apply Android configurations  
  config = withUaePassAndroid(config, props);
  
  return config;
};

module.exports = createRunOncePlugin(withUaePass, "react-native-uaepass", "1.0.0");