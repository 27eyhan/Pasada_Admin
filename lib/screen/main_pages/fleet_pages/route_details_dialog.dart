import 'dart:async';
import 'dart:convert';
// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// dart:js is only used on web; ignore lint for non-web platforms
// ignore: depend_on_referenced_packages
import 'dart:js' as js;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/widgets/responsive_dialog.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_route_dialog.dart';

class RouteDetailsDialog extends StatefulWidget {
  final String routeId;
  final SupabaseClient supabase;
  final VoidCallback? onManageRoute;

  const RouteDetailsDialog({
    super.key,
    required this.routeId,
    required this.supabase,
    this.onManageRoute,
  });

  @override
  State<RouteDetailsDialog> createState() => _RouteDetailsDialogState();
}

class _RouteDetailsDialogState extends State<RouteDetailsDialog> {
  Map<String, dynamic>? route;
  bool isLoading = true;
  String? error;
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  CameraPosition? _initialCamera;
  bool _isLoadingPolyline = false;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      final data = await widget.supabase
          .from('official_routes')
          .select('officialroute_id, route_name, origin_name, destination_name, description, status, created_at, origin_lat, origin_lng, destination_lat, destination_lng, intermediate_coordinates')
          .eq('officialroute_id', widget.routeId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        route = data;
        isLoading = false;
      });
      _buildMapArtifacts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _buildMapArtifacts() {
    if (route == null) return;

    LatLng? origin = _parseLatLng(route!['origin_lat'], route!['origin_lng']);
    LatLng? destination = _parseLatLng(route!['destination_lat'], route!['destination_lng']);

    // Markers for origin/destination
    final markers = <Marker>{};
    if (origin != null) {
      markers.add(Marker(markerId: const MarkerId('origin'), position: origin, infoWindow: const InfoWindow(title: 'Origin')));
    }
    if (destination != null) {
      markers.add(Marker(markerId: const MarkerId('destination'), position: destination, infoWindow: const InfoWindow(title: 'Destination')));
    }
    _markers = markers;

    // Get intermediate coordinates for waypoints
    final List<LatLng> waypoints = [];
    final dynamic inter = route!['intermediate_coordinates'];
    try {
      final dynamic data = inter is String ? jsonDecode(inter) : inter;
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            final lat = item['lat'];
            final lng = item['lng'];
            final ll = _parseLatLng(lat, lng);
            if (ll != null) {
              waypoints.add(ll);
            }
          }
        }
      }
    } catch (e) {
      // Silently handle parsing errors
    }

    // Get road-aligned polyline using Google Routes API v2
    if (origin != null && destination != null) {
        
      setState(() {
        _isLoadingPolyline = true;
      });
      
      _getRoadAlignedPolyline(origin, destination, waypoints).then((points) {
        if (points.isNotEmpty && mounted) {
          final polyline = Polyline(
            polylineId: const PolylineId('route_polyline'),
            color: const Color(0xFF00CC58),
            width: 4,
            points: points,
          );
          setState(() {
            _polylines = {polyline};
            _isLoadingPolyline = false;
          });
        } else {
          _createFallbackPolyline(origin, destination, waypoints);
        }
      }).catchError((error) {
        _createFallbackPolyline(origin, destination, waypoints);
      });
    }

    // Initial camera/bounds
    if (origin != null && destination != null) {
      final bounds = _boundsFromLatLngs([origin, destination, ...waypoints]);
      _initialCamera = CameraPosition(
        target: LatLng(
          (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
          (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        ),
        zoom: 12,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_mapController.isCompleted) return;
        final controller = await _mapController.future;
        controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
      });
    } else if (origin != null) {
      _initialCamera = CameraPosition(target: origin, zoom: 13);
    } else if (destination != null) {
      _initialCamera = CameraPosition(target: destination, zoom: 13);
    }

    if (mounted) setState(() {});
  }

  LatLngBounds _boundsFromLatLngs(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (final ll in list) {
      minLat = (minLat == null) ? ll.latitude : (ll.latitude < minLat ? ll.latitude : minLat);
      maxLat = (maxLat == null) ? ll.latitude : (ll.latitude > maxLat ? ll.latitude : maxLat);
      minLng = (minLng == null) ? ll.longitude : (ll.longitude < minLng ? ll.longitude : minLng);
      maxLng = (maxLng == null) ? ll.longitude : (ll.longitude > maxLng ? ll.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  LatLng? _parseLatLng(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return null;
    double? la;
    double? ln;
    if (lat is num) la = lat.toDouble();
    if (lng is num) ln = lng.toDouble();
    if (lat is String) la = double.tryParse(lat);
    if (lng is String) ln = double.tryParse(lng);
    if (la == null || ln == null) return null;
    return LatLng(la, ln);
  }

  Future<List<LatLng>> _getRoadAlignedPolyline(LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    try {
      // On web, use the JS DirectionsService directly to avoid CORS
      if (kIsWeb) {
        final points = await _getPolylineWeb(origin, destination, waypoints);
        if (points.isNotEmpty) return points;
      }

      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? dotenv.env['GOOGLE_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        return [];
      }

      // Build waypoints string for Google Directions API
      String waypointsParam = '';
      if (waypoints.isNotEmpty) {
        final waypointStrings = waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
        waypointsParam = '&waypoints=$waypointStrings';
      }

      // Use Google Directions API with CORS proxy to avoid CORS issues
      final baseUrl = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '$waypointsParam'
          '&mode=driving'
          '&key=$apiKey';

      // Use a CORS proxy to avoid CORS issues in web browsers
      final url = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(baseUrl)}';


      final response = await http.get(Uri.parse(url));


      if (response.statusCode == 200) {
        final proxyResponse = jsonDecode(response.body);
        
        // The CORS proxy wraps the response in a 'contents' field
        if (proxyResponse['contents'] != null) {
          final data = jsonDecode(proxyResponse['contents']);
          
          if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final legs = route['legs'] as List;
            
            List<LatLng> allPoints = [];
            
            for (final leg in legs) {
              final steps = leg['steps'] as List;
              for (final step in steps) {
                final polyline = step['polyline'];
                if (polyline != null && polyline['points'] != null) {
                  final encodedPolyline = polyline['points'];
                  final decodedPoints = _decodePolyline(encodedPolyline);
                  allPoints.addAll(decodedPoints);
                }
              }
            }
            
            if (allPoints.isNotEmpty) {
              return allPoints;
            }
          } else {
          }
        } else {
        }
      } else {
      }
    } catch (e) {
      throw Exception('Error getting road-aligned polyline: $e');
    }
    return [];
  }

  Future<List<LatLng>> _getPolylineWeb(LatLng origin, LatLng destination, List<LatLng> waypoints) async {
    try {
      final completer = Completer<List<LatLng>>();

      // Build plain objects for JS
      final originObj = {'lat': origin.latitude, 'lng': origin.longitude};
      final destObj = {'lat': destination.latitude, 'lng': destination.longitude};
      final wpObjs = waypoints.map((w) => {'lat': w.latitude, 'lng': w.longitude}).toList();

      // Define callback
      void cb(dynamic encoded, dynamic error) {
        try {
          if (encoded is String && encoded.isNotEmpty) {
            final pts = _decodePolyline(encoded);
            completer.complete(pts);
          } else {
            completer.complete(<LatLng>[]);
          }
        } catch (e) {
          completer.complete(<LatLng>[]);
        }
      }

      // Call the JS helper
      js.context.callMethod('computeRoutePolyline', [originObj, destObj, wpObjs, cb]);

      final result = await completer.future.timeout(const Duration(seconds: 10), onTimeout: () => <LatLng>[]);
      return result;
    } catch (e) {
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;


    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      // Decode longitude
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      // Convert to decimal degrees
      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }


  void _createFallbackPolyline(LatLng origin, LatLng destination, List<LatLng> waypoints) {
    if (!mounted) return;
    
    
    // Create a simple polyline connecting origin -> waypoints -> destination
    final List<LatLng> fallbackPoints = [origin];
    fallbackPoints.addAll(waypoints);
    fallbackPoints.add(destination);
    
    
    final polyline = Polyline(
      polylineId: const PolylineId('route_polyline'),
      color: const Color(0xFF00CC58),
      width: 4,
      points: fallbackPoints,
    );
    
    setState(() {
      _polylines = {polyline};
      _isLoadingPolyline = false;
    });
  }

  void _showEditRouteDialog() {
    if (route == null) return;
    
    showDialog(
      context: context,
      builder: (context) => EditRouteDialog(
        routeId: widget.routeId,
        routeData: route!,
        supabase: widget.supabase,
        onRouteUpdated: () {
          // Refresh the route data when updated
          _fetchRoute();
          if (widget.onManageRoute != null) {
            widget.onManageRoute!();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ResponsiveDialog(
      title: 'Route Details',
      titleIcon: Icons.alt_route,
      child: isLoading
          ? SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          : (error != null || route == null)
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    error ?? 'No data',
                    style: TextStyle(color: isDark ? Palette.darkText : Palette.lightText),
                  ),
                )
              : _buildContent(context, isDark),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsiveCardPadding(context);

    final details = _buildDetails(isDark);
    final map = _buildMap(isDark);

    return Column(
      children: [
        isMobile
            ? Column(
                children: [
                  details,
                  SizedBox(height: padding),
                  SizedBox(height: 260, child: map),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  SizedBox(width: padding),
                  Expanded(child: SizedBox(height: 380, child: map)),
                ],
              ),
        SizedBox(height: padding),
        ResponsiveDialogActions(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.manage_accounts),
                label: const Text('Manage Route'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CC58),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showEditRouteDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetails(bool isDark) {
    final r = route!;
    final labelStyle = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 11, tablet: 12, desktop: 13),
      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
    );
    final valueStyle = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w700,
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 13, tablet: 14, desktop: 15),
      color: isDark ? Palette.darkText : Palette.lightText,
    );

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(label, style: labelStyle),
              ),
              Expanded(
                child: Text(value, style: valueStyle),
              ),
            ],
          ),
        );

    final description = (r['description']?.toString() ?? '').trim();
    final createdAt = (r['created_at']?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1.0),
      ),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveCardPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r['route_name']?.toString() ?? 'Route ${r['officialroute_id']}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
              color: isDark ? Palette.darkText : Palette.lightText,
            ),
          ),
          const SizedBox(height: 12.0),
          row('Route ID', r['officialroute_id']?.toString() ?? 'N/A'),
          row('Origin', r['origin_name']?.toString() ?? 'N/A'),
          row('Destination', r['destination_name']?.toString() ?? 'N/A'),
          row('Status', r['status']?.toString() ?? 'N/A'),
          row('Created', createdAt),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text('Description', style: labelStyle),
            const SizedBox(height: 6.0),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    final camera = _initialCamera ?? const CameraPosition(target: LatLng(14.5995, 120.9842), zoom: 10);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: camera,
            polylines: _polylines,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) async {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              // Apply themed map style
              try {
                await controller.setMapStyle(isDark ? _darkMapStyle : _lightMapStyle);
              } catch (_) {}
            },
          ),
          if (_isLoadingPolyline)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading route...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Minimal Google Maps styles to better match app themes
const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#1e1e1e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#e0e0e0"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#1e1e1e"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#2a2a2a"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f1114"}]}]';

const String _lightMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#ffffff"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#424242"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#f2f2f2"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#e9e9e9"}]},{"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"transit","stylers":[{"visibility":"off"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#d5e7ff"}]}]';


