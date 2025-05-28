import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pasada_admin_application/maps/maps_call_driver.dart'; // Import the service

class Mapscreen extends StatefulWidget {
  // Add parameters to focus on a specific driver
  final dynamic driverToFocus;
  final bool initialShowDriverInfo;
  
  const Mapscreen({
    super.key, 
    this.driverToFocus,
    this.initialShowDriverInfo = false,
  });

  @override
  State<Mapscreen> createState() => MapsScreenState();
}

class MapsScreenState extends State<Mapscreen> with AutomaticKeepAliveClientMixin {
  late GoogleMapController mapController;
  // ignore: unused_field
  GoogleMapController? _internalMapController;
  final LatLng _center =
      const LatLng(14.714213612467042, 120.9997533908128); // Novadeci route
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isMapReady = false;
  LatLng? _driverLocation;

  final DriverLocationService _driverLocationService = DriverLocationService(); // Instantiate the service
  Timer? _locationUpdateTimer; // Timer for periodic updates

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('[MapsScreenState] initState called.');
    
    // Log if we should focus on a specific driver
    if (widget.driverToFocus != null) {
      debugPrint('[MapsScreenState] Should focus on driver: ${widget.driverToFocus}');
    }
    
    // For web platform, we need to ensure the Google Maps API is loaded
    if (kIsWeb) {
      // Check if API key is set
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('Warning: GOOGLE_MAPS_API_KEY is not set in .env file');
      }
      // Set a delay to ensure the API is loaded
      // We still need this delay for the map widget itself on web
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isMapReady = true; // Mark map as ready for rendering
          });
        }
      });
    } else {
      _isMapReady = true;
    }
  }

  @override
  void dispose() {
    debugPrint('[MapsScreenState] dispose starts.');
    _locationUpdateTimer?.cancel();
    debugPrint('[MapsScreenState] Timer cancelled.');

    // The GoogleMap widget itself handles the disposal of its controller and JS resources
    // when it's removed from the widget tree. Explicitly meddling here is often not necessary
    // and can cause issues if not done correctly in sync with the plugin's internal logic.
    
    // Ensure super.dispose() is called synchronously.
    super.dispose(); 
    debugPrint('[MapsScreenState] dispose finished (super.dispose() called).');
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // _internalMapController = controller; // Remove if not used elsewhere
    debugPrint('[MapsScreenState] _onMapCreated called.');

    if (_locationUpdateTimer == null || !_locationUpdateTimer!.isActive) {
        debugPrint('[MapsScreenState] Map controller ready, starting location updates.');
        _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
     // Fetch immediately first time
    _updateDriverMarkers();
    debugPrint('[MapsScreenState] Initial marker update requested.');

    // Start periodic updates (e.g., every 15 seconds)
    _locationUpdateTimer?.cancel(); // Cancel existing timer just in case
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
       debugPrint('[MapsScreenState] Timer fired. Requesting marker update.');
       if (mounted) { // Check if the widget is still mounted
        _updateDriverMarkers();
       }
    });
  }

  Future<void> _updateDriverMarkers() async {
    debugPrint('[MapsScreenState] _updateDriverMarkers called.');
    List<Map<String, dynamic>> driverLocations = await _driverLocationService.fetchDriverLocations();
    debugPrint('[MapsScreenState] Received driver locations: ${driverLocations.length} drivers.');

    Set<Marker> updatedMarkers = {};
    bool foundFocusDriver = false;

    for (var driverData in driverLocations) {
      final String driverId = driverData['driver_id'].toString();
      final LatLng position = driverData['position'];
      final String driverName = driverData['full_name'] ?? 'N/A';
      final String vehicleId = driverData['vehicle_id']?.toString() ?? 'N/A';
      
      // Check if this is the driver we want to focus on
      bool isTargetDriver = widget.driverToFocus != null && 
                           driverId == widget.driverToFocus.toString();
      
      // Store the position of the driver to focus on
      if (isTargetDriver) {
        _driverLocation = position;
        foundFocusDriver = true;
        debugPrint('[MapsScreenState] Found target driver $driverId at position: $position');
        
        // Focus on this driver's location if this is the first update
        if (widget.initialShowDriverInfo && mounted) {
          // Use a delay to ensure the map is fully loaded
          Future.delayed(Duration(milliseconds: 500), () {
            if (mapController != null) {
              // Zoom to the driver's location
              mapController.animateCamera(
                CameraUpdate.newLatLngZoom(position, 17.0),
              );
              
              MarkerId markerId = MarkerId(driverId);
              mapController.showMarkerInfoWindow(markerId);
              debugPrint('[MapsScreenState] Showing info window for driver $driverId');
            }
          });
        }
      }

      updatedMarkers.add(
        Marker(
          markerId: MarkerId(driverId),
          position: position,
          infoWindow: InfoWindow(
            title: 'Driver: $driverName (ID: $driverId)',
            snippet: 'Vehicle ID: $vehicleId\nLocation: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
          ),
          // Highlight the target driver with a different color
          icon: isTargetDriver
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue) 
              : BitmapDescriptor.defaultMarker,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(updatedMarkers);
        debugPrint('[MapsScreenState] setState called with ${updatedMarkers.length} markers.');
        
        // If we're looking for a specific driver but couldn't find them, log it
        if (widget.driverToFocus != null && !foundFocusDriver) {
          debugPrint('[MapsScreenState] Warning: Could not find driver ${widget.driverToFocus} in location data.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint('[MapsScreenState] build called.');

    if (!_isMapReady && kIsWeb) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 15.0,
          ),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              // Center on focused driver if available, otherwise use default center
              mapController.animateCamera(
                CameraUpdate.newLatLng(_driverLocation ?? _center),
              );
            },
            child: Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}
