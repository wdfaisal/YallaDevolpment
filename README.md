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

## Checks

```bash
flutter analyze
flutter test
```
