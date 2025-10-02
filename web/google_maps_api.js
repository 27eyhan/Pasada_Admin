// This script will be used to load the Google Maps API with the key from Flutter
function loadGoogleMapsApi(apiKey) {
  const script = document.getElementById('google-maps-api');
  script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`;
}

// Make the function available to Flutter
window.loadGoogleMapsApi = loadGoogleMapsApi;

function computeRoutePolyline(origin, destination, waypoints, cb) {
  try {
    // Get API key from the loaded script
    const script = document.getElementById('google-maps-api');
    const apiKey = script ? script.src.match(/[?&]key=([^&]+)/)?.[1] : null;
    
    if (!apiKey) {
      cb(null, 'Google Maps API key not found');
      return;
    }

    // Build request body for Google Routes API v2
    const requestBody = {
      origin: {
        location: {
          latLng: {
            latitude: origin.lat,
            longitude: origin.lng,
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: destination.lat,
            longitude: destination.lng,
          }
        }
      },
      travelMode: 'DRIVE',
      routingPreference: 'TRAFFIC_AWARE_OPTIMAL',
      polylineEncoding: 'ENCODED_POLYLINE',
    };

    // Add waypoints if available
    if (Array.isArray(waypoints) && waypoints.length > 0) {
      requestBody.intermediates = waypoints.map(wp => ({
        location: {
          latLng: {
            latitude: wp.lat,
            longitude: wp.lng,
          }
        }
      }));
    }

    const url = `https://routes.googleapis.com/directions/v2:computeRoutes?key=${apiKey}`;

    fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
      },
      body: JSON.stringify(requestBody),
    })
    .then(response => response.json())
    .then(data => {
      if (data.routes && data.routes.length > 0) {
        const route = data.routes[0];
        const polyline = route.polyline;
        
        if (polyline && polyline.encodedPolyline) {
          cb(polyline.encodedPolyline, null);
        } else {
          cb(null, 'No encoded polyline found in Routes API response');
        }
      } else {
        cb(null, 'No routes found in Routes API response');
      }
    })
    .catch(error => {
      cb(null, 'Routes API Error: ' + error.message);
    });
  } catch (e) {
    cb(null, 'computeRoutePolyline exception: ' + e);
  }
}

window.computeRoutePolyline = computeRoutePolyline;
