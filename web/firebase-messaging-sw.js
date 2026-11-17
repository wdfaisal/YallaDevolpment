/* eslint-disable no-undef */
/**
 * Firebase Cloud Messaging service worker for the customer web build.
 *
 * The app never ships Firebase credentials in source control. At deploy time,
 * copy `firebase-config.example.js` to `firebase-config.js` and fill the real
 * project values; that file defines `self.YALLA_FIREBASE_CONFIG`. Without it
 * this worker stays inert and the app reports push as unavailable.
 */
importScripts('https://www.gstatic.com/firebasejs/13.3.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.3.0/firebase-messaging-compat.js');

try {
  importScripts('/firebase-config.js');
} catch (_) {
  // No deploy-time configuration: keep the worker installed but inert.
}

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

const config = self.YALLA_FIREBASE_CONFIG;
const configured =
  config &&
  config.apiKey &&
  config.appId &&
  config.messagingSenderId &&
  config.projectId;

if (configured) {
  firebase.initializeApp(config);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    const notification = payload.notification || {};
    const data = payload.data || {};
    const title = notification.title || data.titleAr || 'Yalla Talabat';
    const body = notification.body || data.bodyAr || '';
    self.registration.showNotification(title, {
      body,
      data,
      icon: '/icons/Icon-192.png',
      badge: '/icons/Icon-192.png',
    });
  });

  self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    const orderId = event.notification.data && event.notification.data.orderId;
    const target = orderId ? `/orders/${orderId}` : '/';
    event.waitUntil(
      self.clients
        .matchAll({ type: 'window', includeUncontrolled: true })
        .then((clients) => {
          for (const client of clients) {
            if ('focus' in client) {
              client.navigate(target);
              return client.focus();
            }
          }
          return self.clients.openWindow(target);
        }),
    );
  });
}
