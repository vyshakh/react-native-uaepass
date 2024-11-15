import React, { useState } from 'react';
import {
  SafeAreaView,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
} from 'react-native';
import { UAEPass } from 'react-native-uaepass';

const UAEPassConfig = {
  env: 'staging', // or production // default staging
  clientId: 'clientId',
  redirectURL: 'com.test://uaepass',
  successHost: 'uaePassSuccess',
  failureHost: 'uaePassFail',
  scheme: 'testscheme',
  scope: 'urn:uae:digitalid:profile',
  locale: 'en',
};

const App = () => {
  const [userData, setData] = useState(null);
  const login = async () => {
    try {
      const response = await UAEPass.login(UAEPassConfig);
      if (response && response.accessCode) {
        setData(response);
      }
    } catch (e) {
      console.log('error', e);
    }
  };

  const logout = async () => {
    try {
      const response = await UAEPass.logout();
      console.log('response', response);
      setData(null);
    } catch (e) {
      console.log('error', e);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {!userData && (
        <TouchableOpacity onPress={login}>
          <Text style={styles.text}>Login</Text>
        </TouchableOpacity>
      )}
      {userData && (
        <View>
          <Text style={styles.text}>{`${JSON.stringify(
            userData,
            null,
            4
          )}`}</Text>
          <TouchableOpacity style={styles.button} onPress={logout}>
            <Text style={styles.text}>Logout</Text>
          </TouchableOpacity>
        </View>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: 'gray',
  },
  text: {
    fontSize: 16,
    color: '#fff',
  },
  button: {
    marginTop: 50,
    padding: 10,
    marginVertical: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;
