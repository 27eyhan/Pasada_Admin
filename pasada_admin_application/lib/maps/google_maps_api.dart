// Conditionally export web or stub implementation
export 'google_maps_api_stub.dart'
    if (dart.library.html) 'google_maps_api_web.dart';
