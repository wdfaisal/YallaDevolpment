# Yalla Talabat — Customer App

Flutter customer app. Live backend only: every value shown comes from the API.

## Run against the local backend

```bash
# backend (terminal 1)
cd ../backend
npm run dev            # listens on 0.0.0.0:4000

# app (terminal 2)
cd ../customer-app
flutter run -d chrome  # web: API host follows the page host
```

The API base URL resolves in this order:

1. `--dart-define=API_BASE_URL=http://host:4000` (always wins)
2. Web: the host that served the page, port `4000`
   (`http://192.168.1.10:8080` → `http://192.168.1.10:4000`)
3. Native: `http://<LAN_HOST>:4000`, where `LAN_HOST` defaults to the
   development machine's Wi-Fi address.

Overrides:

```bash
flutter run --dart-define=LAN_HOST=192.168.1.10
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000
flutter run --dart-define=API_PORT=4000
```

## Try it on a phone (same Wi-Fi)

```bash
flutter build web --release
# serve build/web on 0.0.0.0:8080, then open http://<pc-ip>:8080 on the phone
```

The web build talks to `<pc-ip>:4000` automatically, so the backend URL never
needs to be baked in. The backend must listen on `0.0.0.0` and allow the
phone's origin in `CORS_ORIGINS`.

## Android demo build (Codemagic)

The `android/` platform lives in this folder. Build a demo APK with:

```bash
flutter build apk --release
```

The release manifest includes the `INTERNET` permission and allows cleartext
HTTP, so the APK can reach the LAN backend at `http://10.160.175.182:4000`
(override with `--dart-define=LAN_HOST=...`). For a backend that is not on the
same Wi-Fi, point the app at a public URL instead:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

In Codemagic add the same flag to the build step's build arguments. The Gradle
wrapper (`gradlew`, `gradle-wrapper.jar`) is intentionally not committed;
Flutter regenerates it from the SDK before the Gradle build runs.

Toolchain pinned in `android/` to the lowest versions that Codemagic's newer
Flutter accepts, while staying on artifacts that resolve reliably:

- Gradle 9.5.0 (`android/gradle/wrapper/gradle-wrapper.properties`)
- Android Gradle Plugin 9.1.1 (`android/settings.gradle.kts`)
- Kotlin 2.4.0, JDK 17+, `minSdk 24`, `compileSdk`/`targetSdk` from Flutter

Codemagic builds with a newer Flutter than the local SDK, and its Gradle plugin
enforces minimums at build time (seen in CI: "Gradle 9.3.1 will soon be dropped",
"AGP 9.1.0 is lower than Flutter's minimum supported 9.1.1"). Keep the pair at
Gradle 9.5.0 / AGP 9.1.1 or higher. Avoid AGP 9.2.1: it is published on Google
Maven, but CI failed to resolve its plugin marker
(`Plugin [id: 'com.android.application', version: '9.2.1'] was not found`).
When a plugin "was not found", clear the CI Gradle cache before changing
versions again: a negative module cache entry survives between builds.

## Checks

```bash
flutter analyze
flutter test
```
