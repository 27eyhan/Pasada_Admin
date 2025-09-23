// This script will be used to load the Google Maps API with the key from Flutter
function loadGoogleMapsApi(apiKey) {
  const script = document.getElementById('google-maps-api');
  script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`;
}

// Make the function available to Flutter
window.loadGoogleMapsApi = loadGoogleMapsApi;
