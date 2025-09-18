import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/maps/maps_call_driver.dart'; // Import the service
import 'package:pasada_admin_application/config/palette.dart'; // Import palette for consistent colors
import 'package:pasada_admin_application/config/theme_provider.dart';

class Mapscreen extends StatefulWidget {
  // Add parameters to focus on a specific driver
  final dynamic driverToFocus;
  final bool initialShowDriverInfo;
  
  // Filter parameters
  final Set<String>? selectedStatuses;
  final String? selectedVehicleId;
  final String? sortOption;

  const Mapscreen({
    super.key,
    this.driverToFocus,
    this.initialShowDriverInfo = false,
    this.selectedStatuses,
    this.selectedVehicleId,
    this.sortOption,
  });

  @override
  State<Mapscreen> createState() => MapsScreenState();
}

class MapsScreenState extends State<Mapscreen>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? mapController;
  // ignore: unused_field
  GoogleMapController? _internalMapController;
  final LatLng _center =
      const LatLng(14.714213612467042, 120.9997533908128); // Novadeci route
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isMapReady = false;
  LatLng? _driverLocation;

  final DriverLocationService _driverLocationService =
      DriverLocationService(); // Instantiate the service
  Timer? _locationUpdateTimer; // Timer for periodic updates

  // Custom pin icons cache
  final Map<String, BitmapDescriptor> _customPinIcons = {};

  // Selected driver info for custom overlay
  Map<String, dynamic>? _selectedDriverInfo;
  bool _showDriverOverlay = false;
  
  // Filter state
  Set<String>? _currentSelectedStatuses;
  String? _currentSelectedVehicleId;
  String? _currentSortOption;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('[MapsScreenState] initState called.');

    // Initialize filter state
    _currentSelectedStatuses = widget.selectedStatuses;
    _currentSelectedVehicleId = widget.selectedVehicleId;
    _currentSortOption = widget.sortOption;

    // Load custom pin icons
    _loadCustomPinIcons();

    // Log if we should focus on a specific driver
    if (widget.driverToFocus != null) {
      debugPrint(
          '[MapsScreenState] Should focus on driver: ${widget.driverToFocus}');
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

  // Load custom pin icons from assets
  Future<void> _loadCustomPinIcons() async {
    try {
      debugPrint('[MapsScreenState] Loading custom pin icons...');

      _customPinIcons['idling'] = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(48, 48)),
        'assets/pinIdling.png',
      );

      _customPinIcons['online'] = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(48, 48)),
        'assets/pinOnline.png',
      );

      _customPinIcons['driving'] = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(48, 48)),
        'assets/pinOnline.png', // Use the same icon for driving as online
      );

      _customPinIcons['offline'] = await BitmapDescriptor.asset(
        ImageConfiguration(size: Size(48, 48)),
        'assets/pinOffline.png',
      );

      debugPrint('[MapsScreenState] Custom pin icons loaded successfully');
    } catch (e) {
      debugPrint('[MapsScreenState] Error loading custom pin icons: $e');
      // Fallback to default markers if custom icons fail to load
    }
  }

  // Update filter state
  void updateFilters({
    Set<String>? selectedStatuses,
    String? selectedVehicleId,
    String? sortOption,
  }) {
    setState(() {
      _currentSelectedStatuses = selectedStatuses;
      _currentSelectedVehicleId = selectedVehicleId;
      _currentSortOption = sortOption;
    });
    
    // Refresh markers with new filters
    _updateDriverMarkers();
  }

  // Get the appropriate pin icon based on driver status
  BitmapDescriptor _getPinIcon(String? drivingStatus, bool isTargetDriver) {
    if (isTargetDriver) {
      // Highlight the target driver with a different color (blue default marker)
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }

    final status = drivingStatus?.toLowerCase() ?? 'offline';

    // Return custom icon if available, otherwise fallback to default
    if (_customPinIcons.containsKey(status)) {
      return _customPinIcons[status]!;
    }

    // Fallback to default colored markers if custom icons aren't loaded
    switch (status) {
      case 'idling':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'online':
      case 'driving':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'offline':
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  @override
  void dispose() {
    debugPrint('[MapsScreenState] dispose starts.');

    // Hide overlay immediately to prevent rendering issues
    _showDriverOverlay = false;
    _selectedDriverInfo = null;

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
      debugPrint(
          '[MapsScreenState] Map controller ready, starting location updates.');
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
      if (mounted) {
        // Check if the widget is still mounted
        _updateDriverMarkers();
      }
    });
  }

  // Apply filters to driver data
  List<Map<String, dynamic>> _applyFiltersToDrivers(List<Map<String, dynamic>> driverLocations) {
    if (_currentSelectedStatuses == null && _currentSelectedVehicleId == null) {
      // No filters applied, return all drivers
      return driverLocations;
    }

    List<Map<String, dynamic>> filteredDrivers = driverLocations.where((driver) {
      // Filter by status
      bool statusMatch = true;
      if (_currentSelectedStatuses != null && _currentSelectedStatuses!.isNotEmpty) {
        final status = driver["driving_status"]?.toString() ?? "Offline";

        if (_currentSelectedStatuses!.contains('Online')) {
          // For Online, match any of these statuses
          bool isActive = status.toLowerCase() == "driving" ||
              status.toLowerCase() == "online" ||
              status.toLowerCase() == "idling" ||
              status.toLowerCase() == "active";

          if (_currentSelectedStatuses!.contains('Offline')) {
            // If both Online and Offline are selected, show all
            statusMatch = true;
          } else {
            // Only Online is selected
            statusMatch = isActive;
          }
        } else if (_currentSelectedStatuses!.contains('Offline')) {
          // Only Offline is selected
          bool isOffline = status.toLowerCase() == "offline" ||
              status.toLowerCase() == "";
          statusMatch = isOffline;
        }
      }

      // Filter by vehicle ID
      bool vehicleMatch = _currentSelectedVehicleId == null ||
          driver['vehicle_id']?.toString() == _currentSelectedVehicleId;

      return statusMatch && vehicleMatch;
    }).toList();

    // Apply sorting
    if (_currentSortOption == 'alphabetical') {
      filteredDrivers.sort((a, b) {
        final nameA = a['full_name']?.toString() ?? '';
        final nameB = b['full_name']?.toString() ?? '';
        return nameA.compareTo(nameB);
      });
    } else {
      // numeric sorting is default (by driver ID)
      filteredDrivers.sort((a, b) {
        final idA = int.tryParse(a['driver_id']?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b['driver_id']?.toString() ?? '0') ?? 0;
        return idA.compareTo(idB);
      });
    }

    return filteredDrivers;
  }

  Future<void> _updateDriverMarkers() async {
    debugPrint('[MapsScreenState] _updateDriverMarkers called.');
    List<Map<String, dynamic>> driverLocations =
        await _driverLocationService.fetchDriverLocations();
    debugPrint(
        '[MapsScreenState] Received driver locations: ${driverLocations.length} drivers.');

    // Apply filters to driver locations
    List<Map<String, dynamic>> filteredDriverLocations = _applyFiltersToDrivers(driverLocations);
    debugPrint(
        '[MapsScreenState] After filtering: ${filteredDriverLocations.length} drivers.');

    Set<Marker> updatedMarkers = {};
    bool foundFocusDriver = false;

    for (var driverData in filteredDriverLocations) {
      final String driverId = driverData['driver_id'].toString();
      final LatLng position = driverData['position'];
      final String? drivingStatus = driverData['driving_status'];

      // Check if this is the driver we want to focus on
      bool isTargetDriver = widget.driverToFocus != null &&
          driverId == widget.driverToFocus.toString();

      // Store the position of the driver to focus on
      if (isTargetDriver) {
        _driverLocation = position;
        foundFocusDriver = true;
        debugPrint(
            '[MapsScreenState] Found target driver $driverId at position: $position');

        // Focus on this driver's location if this is the first update
        if (widget.initialShowDriverInfo && mounted) {
          // Use a delay to ensure the map is fully loaded
          Future.delayed(Duration(milliseconds: 500), () {
            if (mapController != null) {
              // Zoom to the driver's location
              mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(position, 17.0),
              );

              // Show custom overlay instead of info window
              setState(() {
                _selectedDriverInfo = driverData;
                _showDriverOverlay = true;
              });
              debugPrint(
                  '[MapsScreenState] Showing custom overlay for driver $driverId');
            }
          });
        }
      }

      updatedMarkers.add(
        Marker(
          markerId: MarkerId(driverId),
          position: position,
          onTap: () {
            // Prevent rapid state changes that could cause assertion errors
            if (mounted && _selectedDriverInfo?['driver_id'] != driverId) {
              // Show custom driver info overlay
              setState(() {
                _selectedDriverInfo = driverData;
                _showDriverOverlay = true;
              });
              debugPrint(
                  '[MapsScreenState] Marker tapped for driver: $driverId');
            }
          },
          // Use custom pin based on driver status
          icon: _getPinIcon(drivingStatus, isTargetDriver),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(updatedMarkers);
        debugPrint(
            '[MapsScreenState] setState called with ${updatedMarkers.length} markers.');

        // If we're looking for a specific driver but couldn't find them, log it
        if (widget.driverToFocus != null && !foundFocusDriver) {
          debugPrint(
              '[MapsScreenState] Warning: Could not find driver ${widget.driverToFocus} in location data.');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint('[MapsScreenState] build called.');

    if (!_isMapReady && kIsWeb) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
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
                mapController?.animateCamera(
                  CameraUpdate.newLatLng(_driverLocation ?? _center),
                );
              },
              child: Icon(Icons.center_focus_strong),
            ),
          ),
          if (mounted && _showDriverOverlay && _selectedDriverInfo != null)
            _buildDriverInfoOverlay(),
        ],
      ),
    );
  }

  // Custom driver info overlay widget
  Widget _buildDriverInfoOverlay() {
    // Comprehensive safety checks
    if (!mounted || !_showDriverOverlay || _selectedDriverInfo == null) {
      return SizedBox.shrink();
    }

    final driver = _selectedDriverInfo!;

    // Validate essential data
    if (driver['driver_id'] == null || driver['position'] == null) {
      debugPrint('[MapsScreenState] Invalid driver data, hiding overlay');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showDriverOverlay = false;
            _selectedDriverInfo = null;
          });
        }
      });
      return SizedBox.shrink();
    }

    final String driverName = driver['full_name']?.toString() ?? 'N/A';
    final String driverId = driver['driver_id']?.toString() ?? 'N/A';
    final String vehicleId = driver['vehicle_id']?.toString() ?? 'N/A';
    final String plateNumber = driver['plate_number']?.toString() ?? 'N/A';
    final String routeId = driver['route_id']?.toString() ?? 'N/A';
    final String? drivingStatus = driver['driving_status']?.toString();
    final LatLng? position = driver['position'];

    if (position == null) {
      return SizedBox.shrink();
    }

    Color statusColor = _getStatusColor(drivingStatus);

    final screenSize = MediaQuery.of(context).size;
    final overlayWidth = screenSize.width * 0.25;
    final maxOverlayHeight = screenSize.height * 0.4;

    // Position overlay in the center-top area (above where pins typically appear)
    return Positioned(
      top: 80, // Position above the typical pin area
      left: (screenSize.width - overlayWidth) / 2, // Center horizontally
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: overlayWidth,
          maxHeight: maxOverlayHeight,
        ),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark = themeProvider.isDarkMode;
            
            return SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    bottom: -8,
                    left: overlayWidth / 2 - 8,
                    child: CustomPaint(
                      size: Size(16, 8),
                      painter: ArrowPainter(color: isDark ? Palette.darkSurface : Palette.lightSurface),
                    ),
                  ),
                  // Main card
                  Material(
                    borderRadius: BorderRadius.circular(12.0),
                    elevation: 6.0,
                    child: Container(
                      width: overlayWidth,
                      decoration: BoxDecoration(
                        color: isDark ? Palette.darkSurface : Palette.lightSurface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                            color: statusColor.withAlpha(100), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withAlpha(150) : Colors.grey.withAlpha(100),
                            spreadRadius: 0,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact header
                          Row(
                            children: [
                              // Status indicator
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  driverName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Palette.darkText : Palette.lightText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showDriverOverlay = false;
                                    _selectedDriverInfo = null;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Palette.darkCard : Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isDark ? Palette.darkText : Palette.lightText,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Compact info in 2 rows
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactInfoItem(
                                    "ID: $driverId", Icons.badge, statusColor),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildCompactInfoItem("Vehicle: $vehicleId",
                                    Icons.directions_car, Palette.orangeColor),
                              ),
                            ],
                          ),

                          SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactInfoItem("Plate: $plateNumber",
                                    Icons.credit_card, Palette.yellowColor),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildCompactInfoItem("Route: $routeId",
                                    Icons.route, Palette.redColor),
                              ),
                            ],
                          ),

                          SizedBox(height: 10),

                          // Status row
                          Container(
                            width: double.infinity,
                            padding:
                                EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(100),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withAlpha(100)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_getStatusIcon(drivingStatus),
                                    size: 16, color: statusColor),
                                SizedBox(width: 6),
                                Text(
                                  _capitalizeFirstLetter(drivingStatus ?? 'N/A'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 12),

                          // Center button only (call button removed)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(position, 18.0),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: Size(0, 40),
                              ),
                              child: Text("Center on Driver",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Simplified compact info item widget
  Widget _buildCompactInfoItem(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Palette.blackColor,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for status
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
      case 'driving':
        return Palette.greenColor;
      case 'idling':
        return Palette.orangeColor;
      case 'offline':
      default:
        return Palette.redColor;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'online':
        return Icons.wifi;
      case 'driving':
        return Icons.directions_car;
      case 'idling':
        return Icons.hourglass_bottom;
      case 'offline':
      default:
        return Icons.wifi_off;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

// Custom painter for the arrow pointer
class ArrowPainter extends CustomPainter {
  final Color color;

  ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
