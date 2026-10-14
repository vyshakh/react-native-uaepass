# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`react-native-uaepass` is a React Native / Expo native module that wraps UAE PASS (UAE's national digital identity) login for iOS and Android. It's a Yarn-workspaces monorepo: the library lives at the repo root and an `example/` app (also an Expo app) consumes it via a local workspace link for manual testing.

## Commands

Run from the repo root (Yarn workspaces — do not use `npm`):

- `yarn` — install deps for the root package and `example/` (also runs `pod-install` for the example iOS app unless `POD_INSTALL=0 yarn`).
- `yarn typecheck` — `tsc --noEmit`.
- `yarn lint` — ESLint over `**/*.{js,ts,tsx}`; `yarn lint --fix` to autofix.
- `yarn test` — Jest (preset `react-native`). Single test: `yarn test -t "<name>"` or `yarn test path/to/file.test.tsx`.
- `yarn prepare` — builds the library with `react-native-builder-bob` (`src/` → `lib/{commonjs,module,typescript}`). Run this after changing `src/` if something depends on `lib/` output.
- `yarn clean` — removes native build dirs and `lib/`.
- `yarn example start|android|ios` — runs the example app's Metro/Android/iOS (shortcut for `yarn workspace react-native-uaepass-example ...`).
- `yarn release` — cuts a release with `release-it` (conventional-commits based version bump, tag, changelog, npm publish).

There is no top-level script for native builds in CI terms; CI uses `turbo run build:android` / `build:ios` (see `turbo.json`, `.github/workflows/ci.yml`) which build the `example/android` and `example/ios` projects against the local library.

Commit messages must follow Conventional Commits (`fix:`, `feat:`, `refactor:`, `docs:`, `test:`, `chore:`) — enforced by commitlint via a pre-commit hook (lefthook/husky also run lint+test on commit).

## Architecture

### Three layers, one JS surface

`src/index.tsx` is the entire public JS API: it just grabs `NativeModules.UAEPass` (throwing the standard "not linked" error via a Proxy if missing) and re-exports it as `UAEPass`. All real logic — building the login UI, handling the OAuth/app-to-app redirect, resolving/rejecting the JS promise — lives in native code:

- **iOS**: `ios/Uaepass.mm` is the Obj-C `RCT_EXTERN_MODULE` bridge declaring `login`/`logout`. `ios/Uaepass.swift` is the actual `UAEPass` native module class (holds static `resolveResponse`/`rejectResponse` promise callbacks and all the UAE PASS config as static vars). `ios/UAEPassViewController.swift` drives the `UAEPassClient` SDK (`ios/LocalPods/UAEPassClient`, bundled via the podspec), presenting an embedded web login view and wiring its success/failure/dismiss callbacks back to `UAEPass.resolve`/`UAEPass.reject`.
- **Android**: `android/src/main/java/com/uaepass/UaepassModule.java` is the `ReactContextBaseJavaModule` exposing `login`/`logout`. `login` starts `LoginActivity` as a Trusted Web Activity and listens via `ActivityEventListener#onActivityResult` for the access code (or error) coming back as intent extras. `UaepassRequestModels` holds the UAE PASS request config; `UaepassPackage` registers the module.
- **Redirect handling (iOS app-to-app flow)**: when the UAE PASS app itself (not the embedded webview) completes login, iOS calls back into the host app via a custom URL scheme. `UAEPass.handleRedirectUrl(_:)` in `Uaepass.swift` is the entry point host apps must call from `AppDelegate`'s `application(_:open:options:)` / `application(_:continue:restorationHandler:)` — it inspects the URL's host against the configured `successHost`/`failureHost` to decide success/failure, resolves/rejects the pending promise, and dismisses the presented UAE PASS flow. This is a frequent source of bugs (see `CFBundleURLTypes` ordering note below) — see commit `a1be040` / issue #25 for the history of what breaks when this wiring is missing or wrong.

### Expo config plugin

`app.plugin.js` → `plugin/index.js` exports `withUaePass`, composing:
- `plugin/withUaePassIos.js`: edits the generated `ios/Podfile` to add the `UAEPassClient` pod, adds `CFBundleURLTypes`/`LSApplicationQueriesSchemes` to `Info.plist`, and — critically — patches the generated `AppDelegate.swift`/`AppDelegate.mm` directly (via `withDangerousMod`, deliberately *not* Expo's `withAppDelegate` helper, which anchors on an `import UIKit` line that newer Expo templates lack) to call `UAEPass().handleRedirectUrl(url)` from the open-URL and continue-userActivity hooks. All patches are idempotent (checked via string markers) since `expo prebuild` can rerun without `--clean`. The UAEPass `CFBundleURLTypes` entry is deliberately inserted **first** in the array because the native SDK reads `CFBundleURLTypes[0].CFBundleURLSchemes[0]` to build its app-to-app callback URL.
- `plugin/withUaePassAndroid.js`: edits `AndroidManifest.xml` (adds `<queries>` for the UAE PASS app packages, an intent-filter on `.MainActivity`, and the `com.uaepass.LoginActivity` activity + intent-filters for success/failure hosts), `android/build.gradle` (adds the `flatDir` pointing at this package's `android/libs`), `android/app/build.gradle` (`manifestPlaceholders` for `appAuthRedirectScheme`), and `gradle.properties` (JVM args + Jetifier).

Required plugin config keys (passed as the second arg to the Expo plugin, i.e. in the app's `app.json`/`app.config.js` plugin props) include `appPackageId`, `uaePassScheme`, `uaePassSuccess`, `uaePassFailure`, `appAuthRedirectScheme`, `uaePassBundleURLName`, `uaePassBundleURLScheme` — the plugin throws descriptive errors at prebuild time if any required key is missing, so when debugging a prebuild failure check `plugin/withUaePassAndroid.js`/`withUaePassIos.js` for which key the thrown message names.

### JS config shape (`UAEPassConfig`, see README "Usage")

`{ env, clientId, redirectURL, successHost, failureHost, scheme, scope, locale }` is passed to `UAEPass.login(config)`. This is the same shape validated natively on both platforms (both reject with "missing parameters" if any required field is empty) — if you add/rename a config field, update it in all three places: `src/index.tsx` types (if typed), `Uaepass.swift`'s `login`, and `UaepassModule.java`'s `login`.

### Build output

The library ships both source (`src`, consumed directly via the `react-native`/`source` package.json fields when Metro resolves it) and prebuilt `lib/{commonjs,module,typescript}` (via `react-native-builder-bob`, for consumers not using Metro's source resolution / for `npm`-published type checking). Native files (`ios/`, `android/`, `*.podspec`, `plugin/`, `app.plugin.js`) are the real implementation; nothing in `android`/`ios` gets transpiled by bob.

### Example app

`example/` is a separate Expo app (own `package.json`, own `node_modules`, linked to the root package via Yarn workspaces + `react-native.config.js`). It reads UAE PASS config from `.env` (see `.env.sample`, typed in `types/env.d.ts` via `react-native-dotenv`/`@env`). Use it to manually verify native changes — JS-only changes to `src/` are picked up without a rebuild, but native (`ios/`, `android/`, `plugin/`) changes require rebuilding the example app (`yarn example ios` / `yarn example android`), and Expo config-plugin changes require re-running `expo prebuild` in `example/`.
