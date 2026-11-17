/**
 * Firebase web app configuration for the service worker.
 *
 * This is the public Firebase web config (the same values ship inside the app
 * bundle). It is NOT a secret: the service-account key used by the backend
 * never appears here. Without this file `firebase-messaging-sw.js` stays inert
 * and the app reports push as unavailable.
 */
self.YALLA_FIREBASE_CONFIG = {
  apiKey: 'AIzaSyCFiIUaHy6RvQc6qNgsvFX7zDVReeEermo',
  authDomain: 'yallatalbat-7cf5a.firebaseapp.com',
  projectId: 'yallatalbat-7cf5a',
  storageBucket: 'yallatalbat-7cf5a.firebasestorage.app',
  messagingSenderId: '149202782210',
  appId: '1:149202782210:web:fc0117a4bda653b1a8bf1b',
};
