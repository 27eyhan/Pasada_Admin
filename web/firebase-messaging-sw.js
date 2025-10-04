// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');
importScripts('./firebase-config.js');

// Initialize Firebase in the service worker
// Firebase config is loaded from firebase-config.js

firebase.initializeApp(firebaseConfig);

// Initialize Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
  
  const notificationTitle = payload.notification?.title || 'Pasada Admin';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/icon-72x72.png',
    tag: payload.data?.type || 'default',
    data: payload.data,
    actions: [
      {
        action: 'view',
        title: 'View Details',
        icon: '/icons/icon-72x72.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss',
        icon: '/icons/icon-72x72.png'
      }
    ],
    requireInteraction: true,
    silent: false,
    vibrate: [200, 100, 200],
    timestamp: Date.now()
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event);
  
  event.notification.close();
  
  const data = event.notification.data;
  const action = event.action;
  
  if (action === 'dismiss') {
    return;
  }
  
  // Handle different notification types
  let urlToOpen = '/';
  
  if (data && data.type) {
    switch (data.type) {
      case 'quota_reached':
        urlToOpen = `/driver/${data.driver_id}`;
        break;
      case 'capacity_overcrowded':
        urlToOpen = '/fleet-management';
        break;
      case 'route_changed':
        urlToOpen = `/routes/${data.route_id}`;
        break;
      case 'heavy_rain_alert':
        urlToOpen = '/weather-alerts';
        break;
      default:
        urlToOpen = '/';
    }
  }
  
  // Open the app with the specific URL
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // If the app is already open, focus it and navigate
        if (clientList.length > 0) {
          const client = clientList[0];
          client.focus();
          client.navigate(urlToOpen);
          return client;
        }
        // If the app is not open, open it
        return clients.openWindow(urlToOpen);
      })
  );
});

// Handle notification close
self.addEventListener('notificationclose', (event) => {
  console.log('Notification closed:', event);
  
  // Track notification dismissal
  if (event.notification.data && event.notification.data.type) {
    // Send analytics event for notification dismissal
    fetch('/api/analytics/notification-dismissed', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: event.notification.data.type,
        timestamp: Date.now()
      })
    }).catch(err => console.log('Analytics error:', err));
  }
});

// Handle push events
self.addEventListener('push', (event) => {
  console.log('Push event received:', event);
  
  if (event.data) {
    const data = event.data.json();
    console.log('Push data:', data);
    
    // You can add custom logic here for different push types
    if (data.type === 'urgent') {
      // Handle urgent notifications differently
      console.log('Urgent notification received');
    }
  }
});

// Handle service worker updates
self.addEventListener('message', (event) => {
  console.log('Service worker message:', event);
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Handle service worker activation
self.addEventListener('activate', (event) => {
  console.log('Service worker activated');
  
  event.waitUntil(
    clients.claim()
  );
});

// Handle service worker installation
self.addEventListener('install', (event) => {
  console.log('Service worker installed');
  
  // Force activation of the new service worker
  self.skipWaiting();
});
