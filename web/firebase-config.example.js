/**
 * Template for the web push service worker configuration.
 *
 * Copy this file to `firebase-config.js` in the deployed web root (next to
 * `firebase-messaging-sw.js`) and fill the values from the Firebase console:
 * Project settings → General → Your apps → Web app → SDK setup and
 * configuration. The file is read by `firebase-messaging-sw.js` only; the app
 * itself receives the same values through `--dart-define` at build time.
 *
 * These are public web config values (they ship inside every web bundle). The
 * service-account key used by the backend is the real secret and must never
 * appear here.
 */
self.YALLA_FIREBASE_CONFIG = {
  apiKey: '',
  authDomain: '',
  projectId: '',
  storageBucket: '',
  messagingSenderId: '',
  appId: '',
};
