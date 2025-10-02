// This script will be used to load the Google Maps API with the key from Flutter
function loadGoogleMapsApi(apiKey) {
  const script = document.getElementById('google-maps-api');
  script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`;
}

// Make the function available to Flutter
window.loadGoogleMapsApi = loadGoogleMapsApi;

function computeRoutePolyline(origin, destination, waypoints, cb) {
  try {
    // Validate input parameters
    if (!origin || !destination || !origin.lat || !origin.lng || !destination.lat || !destination.lng) {
      cb(null, 'Invalid origin or destination coordinates');
      return;
    }

    // Check if Google Maps API is loaded
    if (typeof google === 'undefined' || !google.maps) {
      cb(null, 'Google Maps API not loaded');
      return;
    }

    // Use Google Maps JavaScript API DirectionsService
    const directionsService = new google.maps.DirectionsService();
    
    const request = {
      origin: new google.maps.LatLng(origin.lat, origin.lng),
      destination: new google.maps.LatLng(destination.lat, destination.lng),
      travelMode: google.maps.TravelMode.DRIVING,
      optimizeWaypoints: true,
    };

    // Add waypoints if available
    if (Array.isArray(waypoints) && waypoints.length > 0) {
      request.waypoints = waypoints.map(wp => ({
        location: new google.maps.LatLng(wp.lat, wp.lng),
        stopover: true
      }));
    }

    directionsService.route(request, (result, status) => {
      if (status === google.maps.DirectionsStatus.OK && result.routes && result.routes.length > 0) {
        const route = result.routes[0];
        const overviewPath = route.overview_path;
        
        if (overviewPath && overviewPath.length > 0) {
          // Convert Google Maps LatLng objects to encoded polyline
          const points = overviewPath.map(point => ({
            lat: point.lat(),
            lng: point.lng()
          }));
          const encodedPolyline = encodePolyline(points);
          cb(encodedPolyline, null);
        } else {
          cb(null, 'No route path found');
        }
      } else {
        cb(null, 'Directions request failed: ' + status);
      }
    });
  } catch (e) {
    cb(null, 'computeRoutePolyline exception: ' + e);
  }
}

// Removed fallbackToDirectionsAPI as we now use Google Maps JavaScript API directly

// Helper function to decode polyline
function decodePolyline(encoded) {
  const points = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    // Decode latitude
    let shift = 0;
    let result = 0;
    let b;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlat = ((result & 1) !== 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    // Decode longitude
    shift = 0;
    result = 0;
    do {
      b = encoded.charCodeAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    const dlng = ((result & 1) !== 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    points.push({
      lat: lat / 1e5,
      lng: lng / 1e5
    });
  }
  return points;
}

// Helper function to encode polyline
function encodePolyline(points) {
  let encoded = '';
  let lat = 0;
  let lng = 0;

  for (const point of points) {
    const latDiff = Math.round((point.lat * 1e5) - lat);
    const lngDiff = Math.round((point.lng * 1e5) - lng);
    
    lat += latDiff;
    lng += lngDiff;
    
    encoded += encodeSignedNumber(latDiff);
    encoded += encodeSignedNumber(lngDiff);
  }
  
  return encoded;
}

function encodeSignedNumber(num) {
  const sgn_num = num << 1;
  if (num < 0) {
    sgn_num = ~(sgn_num);
  }
  return encodeUnsignedNumber(sgn_num);
}

function encodeUnsignedNumber(num) {
  let encoded = '';
  while (num >= 0x20) {
    encoded += String.fromCharCode((0x20 | (num & 0x1f)) + 63);
    num >>= 5;
  }
  encoded += String.fromCharCode(num + 63);
  return encoded;
}

window.computeRoutePolyline = computeRoutePolyline;
