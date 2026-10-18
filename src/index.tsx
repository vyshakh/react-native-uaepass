import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-uaepass' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

export type UAEPassEnvironment = 'staging' | 'production';

export interface UAEPassConfig {
  /** UAE PASS environment. Anything other than `production` uses staging. */
  env: UAEPassEnvironment;
  clientId: string;
  /** Must match the redirect URI registered with UAE PASS. */
  redirectURL: string;
  /** Host UAE PASS calls back on after a successful app-to-app login. */
  successHost: string;
  /** Host UAE PASS calls back on after a failed or cancelled app-to-app login. */
  failureHost: string;
  /** Your app's URL scheme (Android LoginActivity intent filter). */
  scheme: string;
  /** e.g. `urn:uae:digitalid:profile:general` */
  scope: string;
  /** UI language. Defaults to `en`. */
  locale?: 'en' | 'ar';
  /**
   * OAuth `state` to send. A random value is generated per login when omitted;
   * either way it is returned in {@link UAEPassLoginResult.state}.
   */
  state?: string;
  /**
   * Android only: when the UAE PASS app is not installed, log in through a
   * plain WebView instead of the SDK's dialog.
   */
  useAndroidCustomWebView?: boolean;
}

export interface UAEPassLoginResult {
  /**
   * Authorization code. Exchange it for an access token on your backend —
   * the client secret must never ship in the app.
   */
  accessCode: string;
  /** The `state` sent with this login request. */
  state?: string;
}

/** `code` values of errors rejected by {@link UAEPassModule.login}. */
export const UAEPassErrorCode = {
  MISSING_PARAMETERS: 'MISSING_PARAMETERS',
  /**
   * The user backed out, either in the login screen or in the UAE PASS app.
   * Includes the OAuth errors UAE PASS documents as a user cancellation:
   * `access_denied`, `cancelled`, `cancelledOnApp`, `invalid_request`,
   * `login_required` (see `userInfo.error`).
   */
  CANCELLED: 'CANCELLED',
  /** Any other failure; see `message` and `userInfo.error`. */
  LOGIN_FAILED: 'LOGIN_FAILED',
  STATE_MISMATCH: 'STATE_MISMATCH',
  /** A second `login()` started before this one finished. */
  SUPERSEDED: 'SUPERSEDED',
} as const;

export type UAEPassErrorCode =
  (typeof UAEPassErrorCode)[keyof typeof UAEPassErrorCode];

/**
 * What UAE PASS itself returned, when the failure came from UAE PASS (as
 * opposed to, say, the user closing the login screen or the device being
 * offline). Use it to show the message the UAE PASS text-message guidelines
 * ask for: https://docs.uaepass.ae/guidelines/design-guidelines/text-message-guidelines
 */
export interface UAEPassErrorInfo {
  /**
   * The OAuth `error` value exactly as UAE PASS sent it, e.g.
   * `access_denied`, `cancelledOnApp`, `invalid_request`, `login_required`.
   */
  error?: string;
  /** The OAuth `error_description`, when UAE PASS sent one (iOS and the Android custom web view only). */
  errorDescription?: string;
}

/** The error `UAEPass.login()` rejects with. */
export interface UAEPassError extends Error {
  code: UAEPassErrorCode;
  userInfo?: UAEPassErrorInfo | null;
}

const errorCodes = new Set<string>(Object.values(UAEPassErrorCode));

/** Narrows a caught value to the error `UAEPass.login()` rejects with. */
export function isUAEPassError(error: unknown): error is UAEPassError {
  return (
    typeof error === 'object' &&
    error !== null &&
    errorCodes.has((error as { code?: unknown }).code as string)
  );
}

export interface UAEPassModule {
  login(config: UAEPassConfig): Promise<UAEPassLoginResult>;
  /** Clears UAE PASS web session cookies so the next login starts fresh. */
  logout(): Promise<unknown>;
}

const UAEPass: UAEPassModule = NativeModules.UAEPass
  ? NativeModules.UAEPass
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export { UAEPass };
