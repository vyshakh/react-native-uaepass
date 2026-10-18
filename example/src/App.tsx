import { useState } from 'react';
import {
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import {
  UAEPass,
  UAEPassErrorCode,
  isUAEPassError,
  type UAEPassConfig,
  type UAEPassLoginResult,
} from 'react-native-uaepass';

// EXPO_PUBLIC_* values come from example/.env (see .env.sample) and are
// inlined at bundle time.
const config: UAEPassConfig = {
  env:
    process.env.EXPO_PUBLIC_UAEPASS_ENV === 'production'
      ? 'production'
      : 'staging',
  clientId: process.env.EXPO_PUBLIC_UAEPASS_CLIENT_ID ?? '',
  redirectURL: process.env.EXPO_PUBLIC_UAEPASS_REDIRECT_URL ?? '',
  successHost: process.env.EXPO_PUBLIC_UAEPASS_SUCCESS_HOST ?? '',
  failureHost: process.env.EXPO_PUBLIC_UAEPASS_FAILURE_HOST ?? '',
  scheme: process.env.EXPO_PUBLIC_UAEPASS_SCHEME ?? '',
  scope: process.env.EXPO_PUBLIC_UAEPASS_SCOPE ?? '',
  locale: process.env.EXPO_PUBLIC_UAEPASS_LOCALE === 'ar' ? 'ar' : 'en',
  useAndroidCustomWebView: false,
};

type Status =
  | { kind: 'idle' }
  | { kind: 'busy' }
  | { kind: 'success'; result: UAEPassLoginResult }
  | {
      kind: 'error';
      code: string;
      message: string;
      /** UAE PASS's own OAuth `error`, e.g. access_denied, cancelledOnApp. */
      uaePassError?: string;
    };

export default function App() {
  const [status, setStatus] = useState<Status>({ kind: 'idle' });

  const login = async () => {
    setStatus({ kind: 'busy' });
    try {
      const result = await UAEPass.login(config);
      // In a real app, send result.accessCode to your backend and exchange it
      // for an access token there.
      setStatus({ kind: 'success', result });
    } catch (e) {
      setStatus(
        isUAEPassError(e)
          ? {
              kind: 'error',
              code: e.code,
              message: e.message,
              uaePassError: e.userInfo?.error,
            }
          : { kind: 'error', code: 'UNKNOWN', message: String(e) }
      );
    }
  };

  const logout = async () => {
    await UAEPass.logout();
    setStatus({ kind: 'idle' });
  };

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        <StatusBar style="dark" />
        <ScrollView contentContainerStyle={styles.content}>
          <Text style={styles.title}>UAE PASS</Text>
          <Text style={styles.subtitle}>
            {config.env} · {config.clientId || 'no clientId set in .env'}
          </Text>

          {status.kind === 'success' && (
            <View style={styles.card}>
              <Text style={styles.label}>Access code</Text>
              <Text selectable style={styles.value}>
                {status.result.accessCode}
              </Text>
              <Text style={styles.label}>State</Text>
              <Text selectable style={styles.value}>
                {status.result.state ?? '—'}
              </Text>
            </View>
          )}

          {status.kind === 'error' && (
            <View style={[styles.card, styles.errorCard]}>
              <Text style={styles.label}>
                {status.code === UAEPassErrorCode.CANCELLED
                  ? 'Cancelled'
                  : status.code}
              </Text>
              <Text style={styles.value}>{status.message}</Text>
              {status.uaePassError && (
                <Text selectable style={styles.value}>
                  error={status.uaePassError}
                </Text>
              )}
            </View>
          )}

          <Pressable
            accessibilityRole="button"
            disabled={status.kind === 'busy'}
            onPress={login}
            style={({ pressed }) => [
              styles.button,
              (pressed || status.kind === 'busy') && styles.buttonPressed,
            ]}
          >
            <Text style={styles.buttonText}>
              {status.kind === 'busy' ? 'Signing in…' : 'Login with UAE PASS'}
            </Text>
          </Pressable>

          {status.kind === 'success' && (
            <Pressable
              accessibilityRole="button"
              onPress={logout}
              style={styles.linkButton}
            >
              <Text style={styles.linkText}>Logout</Text>
            </Pressable>
          )}
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: 24,
    gap: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    textAlign: 'center',
  },
  subtitle: {
    color: '#666',
    textAlign: 'center',
  },
  card: {
    borderRadius: 12,
    padding: 16,
    backgroundColor: '#f2f4f5',
    gap: 4,
  },
  errorCard: {
    backgroundColor: '#fdecea',
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: '#444',
  },
  value: {
    fontSize: 15,
    fontFamily: Platform.select({ ios: 'Menlo', default: 'monospace' }),
  },
  button: {
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    backgroundColor: '#000',
  },
  buttonPressed: {
    opacity: 0.6,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  linkButton: {
    alignItems: 'center',
    padding: 8,
  },
  linkText: {
    fontSize: 16,
    color: '#0a66c2',
  },
});
