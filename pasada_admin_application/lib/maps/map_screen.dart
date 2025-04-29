import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Mapscreen extends StatefulWidget {
  const Mapscreen({super.key});

  @override
  State<Mapscreen> createState() => MapsScreenState();
}

class MapsScreenState extends State<Mapscreen> {
  late GoogleMapController mapController;
  final LatLng _center =
      const LatLng(14.714213612467042, 120.9997533908128); // Novadeci route
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // For web platform, we need to ensure the Google Maps API is loaded
    if (kIsWeb) {
      // Check if API key is set
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('Warning: GOOGLE_MAPS_API_KEY is not set in .env file');
      }
      // Set a delay to ensure the API is loaded
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isMapReady = true;
          });
        }
      });
    } else {
      _isMapReady = true;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Add initial markers here if needed
    setState(() {
      // _markers.add(
      //   Marker(
      //     markerId: MarkerId('manila_center'),
      //     position: _center,
      //     infoWindow: InfoWindow(title: 'Manila'),
      //   ),
      // );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapReady && kIsWeb) {
      // Show loading indicator while waiting for the Google Maps API to load
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
        // Add a button to center on user location
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              // Add functionality to center on user location
              mapController.animateCamera(
                CameraUpdate.newLatLng(_center),
              );
            },
            child: Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}
