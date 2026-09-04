# Releasing notsince to Google Play

Everything in the repo is ready. What remains needs your keys, your Play
account, or a device.

---

## 1. Create the upload key (once)

```bash
keytool -genkey -v -keystore notsince-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Put the `.jks` **outside the repo** (or anywhere — `*.jks` is gitignored), then
create `android/key.properties` from `android/key.properties.example`:

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/absolute/path/to/notsince-upload.jks
```

> Back this file and the keystore up somewhere you will still have in five
> years. Losing the upload key means asking Google to reset it; losing it
> *without* Play App Signing enrolled means you can never update the app.

`android/key.properties`, `*.jks` and `*.keystore` are all gitignored. The
release build falls back to debug signing **only** when no keystore is
configured, so `flutter run --release` still works on a fresh checkout — check
the build output before uploading.

## 2. Build

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols
```

Output: `build/app/outputs/bundle/release/app-release.aab`

The AAB is ~50MB, but that is mostly native debug symbols and the R8 mapping
file, which Play strips. **An arm64 phone downloads about 9.8MB.**

Upload `build/symbols` to Play alongside the bundle (or keep it) — without it,
obfuscated Dart stack traces in crash reports are unreadable.

## 3. Store listing assets

Already generated in `store/`:

| File | Use |
|---|---|
| `play_icon_512.png` | App icon (512×512) |
| `play_feature_graphic_1024x500.png` | Feature graphic |

**Still needed: screenshots.** Play requires at least 2 phone screenshots
(min 320px, max 3840px, 16:9 or 9:16). Take them on the device with
`flutter run --release`, ideally: dashboard with a habit going, the habit tab
showing the plant, the alarms list, and the notes/tasks grid.

## 4. Three declarations Play will demand

The app requests permissions Google restricts. Each needs a form filled in, and
a wrong answer here is the most likely cause of a rejection.

**`USE_FULL_SCREEN_INTENT`** — restricted to alarm, timer and calling apps.
notsince qualifies as an alarm clock. Declare it as such: the permission shows
the ring screen over the lock screen when a user-set alarm fires.

**`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`** — restricted to apps whose core
function is alarms or calendar events. Same justification.

**Data safety form** — answer:

- Does your app collect or share any user data? → **No**
- Is all user data encrypted in transit? → n/a, no data leaves the device
- Do you provide a way to request data deletion? → **Yes**, in-app
  (Settings → Remove all data)

`READ_EXTERNAL_STORAGE` is declared by the `alarm` plugin and is **removed** in
our manifest via `tools:node="remove"`, because notsince only plays bundled
sounds. If a Play scan reports it, the merged manifest is the thing to check —
it should not be there.

## 5. Privacy policy URL

Play requires the policy at a public URL, not only in-app. Host
`store/web/privacy-policy.html` + `store/web/policy.css`, then set the URL in
**two** places or they will drift:

1. Play Console → App content → Privacy policy
2. `lib/core/app_info/app_info.dart` → `AppInfo.privacyUrl`

`AppInfo.termsUrl` is still `example.com` — either host the terms too (the text
is in `lib/features/legal/presentation/legal_text.dart`) or drop the constant.

## 6. Before you upload

- [ ] `flutter analyze` clean, `flutter test` green (99 tests)
- [ ] Installed the release build on a real device and confirmed an alarm
      actually rings — release mode is where R8 stripping would show up, and
      the alarm path is the one thing tests cannot cover
- [ ] `AppInfo.privacyUrl` points at the hosted page
- [ ] Version bumped in `pubspec.yaml` **and** `AppInfo.version` (currently
      `1.0.0+1`)
- [ ] Screenshots taken

## Known issues

**Kotlin Gradle Plugin warning.** `alarm` and `flutter_timezone` still apply
KGP themselves. Harmless today; a future Flutter will refuse to build until
those plugins migrate. Not fixable from here — it is upstream.

**`permission_handler` is pinned to 12.x.** Version 13 requires compileSdk 37,
which Android Gradle Plugin 9.1.0 does not support. Reason is commented in
`pubspec.yaml`; revisit when AGP updates.

**iOS is reminder-only.** Without the Critical Alerts entitlement an iOS alarm
cannot bypass silent mode. Android-only release for now.
