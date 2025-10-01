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
  bool _isRefreshing = false; // UI state for manual refresh
  DateTime? _lastAutoSnackAt; // throttle automatic snackbars

  // Custom pin icons cache
  final Map<String, BitmapDescriptor> _customPinIcons = {};

  // Removed overlay fields since we now use responsive modal
  
  // Filter state
  Set<String>? _currentSelectedStatuses;
  String? _currentSelectedVehicleId;
  String? _currentSortOption;

  // Map style state (for light/dark mode)
  String? _appliedMapStyle;

  // Compact dark style JSON for Google Maps
  static const String _darkMapStyle = '[{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},{"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},{"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},{"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},{"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},{"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}]';

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

    // Apply initial map style based on current theme
    try {
      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      _applyMapStyleForTheme(isDark);
    } catch (_) {
      // Provider may not be available very early; safe to ignore
    }

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
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      debugPrint('[MapsScreenState] Timer fired. Requesting marker update.');
      if (!mounted) return;
      final ok = await _updateDriverMarkers();
      if (!mounted) return;
      if (ok) {
        // Throttle auto snackbars to once per 60 seconds
        final now = DateTime.now();
        if (_lastAutoSnackAt == null || now.difference(_lastAutoSnackAt!).inSeconds >= 60) {
          _lastAutoSnackAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Locations refreshed'),
              backgroundColor: Palette.greenColor,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  // Apply Google Map style based on theme, with simple deduping
  Future<void> _applyMapStyleForTheme(bool isDarkMode) async {
    if (mapController == null) return;
    final desired = isDarkMode ? 'dark' : 'light';
    if (_appliedMapStyle == desired) return;
    await mapController!.setMapStyle(isDarkMode ? _darkMapStyle : null);
    _appliedMapStyle = desired;
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

  Future<bool> _updateDriverMarkers() async {
    debugPrint('[MapsScreenState] _updateDriverMarkers called.');
    List<Map<String, dynamic>> driverLocations = [];
    try {
      driverLocations = await _driverLocationService.fetchDriverLocations();
    } catch (e) {
      debugPrint('[MapsScreenState] fetchDriverLocations error: $e');
      return false;
    }
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
                // Removed overlay fields since we now use responsive modal
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
            // Present responsive modal with driver details
            _presentDriverDetailsModal(driverData);
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
    return true;
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              // Ensure map style follows theme changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _applyMapStyleForTheme(themeProvider.isDarkMode);
              });
              return GoogleMap(
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
              );
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Manual refresh button (matched size)
                FloatingActionButton(
                  heroTag: 'refreshFab',
                  onPressed: _isRefreshing
                      ? null
                      : () async {
                          setState(() { _isRefreshing = true; });
                          try {
                            final ok = await _updateDriverMarkers();
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Locations refreshed'),
                                  backgroundColor: Palette.greenColor,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                            // brief debounce to communicate action
                            await Future.delayed(const Duration(milliseconds: 500));
                          } finally {
                            if (mounted) setState(() { _isRefreshing = false; });
                          }
                        },
                  backgroundColor: Palette.blackColor,
                  tooltip: _isRefreshing ? 'Refreshing…' : 'Refresh locations',
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                ),
                const SizedBox(width: 10),
                // Center/redirect button (green)
                FloatingActionButton(
                  heroTag: 'centerFab',
                  backgroundColor: Palette.greenColor,
                  onPressed: () {
                    // Center on focused driver if available, otherwise use default center
                    mapController?.animateCamera(
                      CameraUpdate.newLatLng(_driverLocation ?? _center),
                    );
                  },
                  tooltip: 'Center map',
                  child: const Icon(Icons.center_focus_strong, color: Colors.white),
                ),
              ],
            ),
          ),
          // Remove old overlay usage in favor of responsive modal
          // if (mounted && _showDriverOverlay && _selectedDriverInfo != null)
          //   _buildDriverInfoOverlay(),
        ],
      ),
    );
  }

  void _presentDriverDetailsModal(Map<String, dynamic> driver) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 700;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: _buildDriverDetailsContent(driver, isDark, maxWidth: size.width),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final double vw = size.width;
          final double maxDialogWidth = (
            vw >= 1400 ? vw * 0.35 :
            vw >= 1100 ? vw * 0.45 :
            vw >= 900 ? vw * 0.55 : vw * 0.7
          ).clamp(360.0, 820.0);
          final double maxDialogHeight = (size.height * 0.85).clamp(420.0, size.height * 0.9);
          final Color surface = isDark ? Palette.darkSurface : Palette.lightSurface;
          final Color borderColor = isDark ? Palette.darkBorder : Palette.lightBorder;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withAlpha(120) : Colors.black.withAlpha(40),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxDialogWidth,
                  maxHeight: maxDialogHeight,
                ),
                child: _buildDriverDetailsContent(driver, isDark, maxWidth: maxDialogWidth),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildDriverDetailsContent(Map<String, dynamic> driver, bool isDark, {double? maxWidth}) {
    final Color textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
    final String driverName = driver['full_name']?.toString() ?? 'N/A';
    final String driverId = driver['driver_id']?.toString() ?? 'N/A';
    final String vehicleId = driver['vehicle_id']?.toString() ?? 'N/A';
    final String plateNumber = driver['plate_number']?.toString() ?? 'N/A';
    final String routeId = driver['route_id']?.toString() ?? 'N/A';
    final String? drivingStatus = driver['driving_status']?.toString();
    final LatLng? position = driver['position'];

    final Color statusColor = _getStatusColor(drivingStatus);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  driverName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close, size: 18, color: textColor.withAlpha(200)),
                tooltip: 'Close',
              )
            ],
          ),
          const SizedBox(height: 16),

          // Info chips in a breathable Wrap (weather-like cards)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _infoChip('ID: $driverId', Icons.badge, statusColor, textColor, isDark, maxWidth: maxWidth),
              _infoChip('Vehicle: $vehicleId', Icons.directions_car, Palette.orangeColor, textColor, isDark, maxWidth: maxWidth),
              _infoChip('Plate: $plateNumber', Icons.credit_card, Palette.yellowColor, textColor, isDark, maxWidth: maxWidth),
              _infoChip('Route: $routeId', Icons.route, Palette.redColor, textColor, isDark, maxWidth: maxWidth),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withAlpha(100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getStatusIcon(drivingStatus), size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  _capitalizeFirstLetter(drivingStatus ?? 'N/A'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: position == null
                  ? null
                  : () {
                      mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(position, 18.0),
                      );
                      Navigator.of(context).maybePop();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Palette.darkPrimary : Palette.lightPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 44),
              ),
              child: const Text('Center on Driver', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String text, IconData icon, Color accent, Color textColor, bool isDark, {double? maxWidth}) {
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7);
    final double chipWidth = (maxWidth != null) ? (maxWidth / 2) - 26 : 180; // approx two per row
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 140, maxWidth: chipWidth),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        elevation: isDark ? 0 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
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
