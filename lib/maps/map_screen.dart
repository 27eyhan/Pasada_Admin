import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  // Cache for labeled icons by driver id and status key
  final Map<String, BitmapDescriptor> _labeledIconCache = {};

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

    // Initialize filter state
    _currentSelectedStatuses = widget.selectedStatuses;
    _currentSelectedVehicleId = widget.selectedVehicleId;
    _currentSortOption = widget.sortOption;

    // Load custom pin icons
    _loadCustomPinIcons();

    // For web platform, we need to ensure the Google Maps API is loaded
    if (kIsWeb) {
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

    } catch (e) {
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

    _locationUpdateTimer?.cancel();

    // The GoogleMap widget itself handles the disposal of its controller and JS resources
    // when it's removed from the widget tree. Explicitly meddling here is often not necessary
    // and can cause issues if not done correctly in sync with the plugin's internal logic.

    // Ensure super.dispose() is called synchronously.
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // _internalMapController = controller; // Remove if not used elsewhere

    // Apply initial map style based on current theme
    try {
      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      _applyMapStyleForTheme(isDark);
    } catch (_) {
      // Provider may not be available very early; safe to ignore
    }

    if (_locationUpdateTimer == null || !_locationUpdateTimer!.isActive) {
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    // Fetch immediately first time
    _updateDriverMarkers();

    // Start periodic updates (e.g., every 15 seconds)
    _locationUpdateTimer?.cancel(); // Cancel existing timer just in case
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
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
    List<Map<String, dynamic>> driverLocations = [];
    try {
      driverLocations = await _driverLocationService.fetchDriverLocations();
    } catch (e) {
      return false;
    }

    // Apply filters to driver locations
    List<Map<String, dynamic>> filteredDriverLocations = _applyFiltersToDrivers(driverLocations);

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
            }
          });
        }
      }

      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final bool isMobile = MediaQuery.of(context).size.width < 700;
      final int? capVal = (driverData['passenger_capacity'] as num?)?.toInt();
      final String cacheKey = 'id:$driverId:${(drivingStatus ?? 'offline').toLowerCase()}:dark=$isDark:mobile=$isMobile:cap=${capVal ?? 'na'}';
      BitmapDescriptor iconDescriptor;
      if (_labeledIconCache.containsKey(cacheKey)) {
        iconDescriptor = _labeledIconCache[cacheKey]!;
      } else {
        final baseIcon = _getPinIcon(drivingStatus, isTargetDriver);
        iconDescriptor = await _buildLabeledMarker(
          baseIcon,
          driverId,
          isDark: isDark,
          isMobile: isMobile,
          capacity: capVal,
        );
        _labeledIconCache[cacheKey] = iconDescriptor;
      }

      updatedMarkers.add(
        Marker(
          markerId: MarkerId(driverId),
          position: position,
          onTap: () {
            // Present responsive modal with driver details
            _presentDriverDetailsModal(driverData);
          },
          icon: iconDescriptor,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(updatedMarkers);

        // If we're looking for a specific driver but couldn't find them, log it
        if (widget.driverToFocus != null && !foundFocusDriver) {
          throw Exception('Could not find driver ${widget.driverToFocus} in location data.');
        }
      });
    }
    return true;
  }

  // Build a labeled marker with Google landmark pin style
  Future<BitmapDescriptor> _buildLabeledMarker(
    BitmapDescriptor basePin,
    String driverId, {
    required bool isDark,
    required bool isMobile,
    int? capacity,
  }) async {
    // Determine canvas size based on layout
    final int pinWidth = isMobile ? 96 : 120; // Smaller on mobile
    final int pinHeight = isMobile ? 96 : 120;
    final int labelHeight = isMobile ? 24 : 32; // Slightly smaller label on mobile
    final int canvasWidth = pinWidth;
    final int canvasHeight = pinHeight + labelHeight + 8; // spacing

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()));

    // Draw label background (rounded pill with shadow)
    final RRect labelRect = RRect.fromLTRBR(
      12.0,
      8.0,
      (canvasWidth - 12).toDouble(),
      (8 + labelHeight).toDouble(),
      Radius.circular(isMobile ? 12 : 16), // More rounded for Google style
    );
    
    // Add subtle shadow to label
    final Paint labelShadow = Paint()
      ..color = Colors.black.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRRect(labelRect.shift(const Offset(0, 1)), labelShadow);
    
    final Paint labelPaint = Paint()
      ..color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA);
    canvas.drawRRect(labelRect, labelPaint);

    // Draw label border
    final Paint labelBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0);
    canvas.drawRRect(labelRect, labelBorder);

    // Draw label text (driver ID)
    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: isMobile ? 13 : 15,
        fontWeight: FontWeight.w700,
      ),
    )..pushStyle(ui.TextStyle(color: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A)))
     ..addText('#$driverId');
    final ui.Paragraph paragraph = pb.build()
      ..layout(ui.ParagraphConstraints(width: canvasWidth - 24));
    canvas.drawParagraph(paragraph, Offset(12, 8 + (labelHeight - paragraph.height) / 2));

    // Draw Google landmark style pin
    final double pinCenterX = canvasWidth / 2;
    final double pinTop = labelHeight + 16;

    // Google landmark pin colors based on status
    final Color pinColor = _getGoogleLandmarkPinColor(driverId, isDark);
    final Color pinAccent = _getGoogleLandmarkPinAccent(driverId, isDark);
    
    // Create the teardrop pin shape (Google landmark style)
    final Path pinPath = Path();
    final double pinRadius = isMobile ? 20.0 : 24.0;
    final double pinBottomY = pinTop + (isMobile ? 50.0 : 60.0);
    final double pinPointY = pinBottomY + (isMobile ? 16.0 : 20.0);
    
    // Create teardrop shape: circle top + pointed bottom
    pinPath.addArc(
      Rect.fromCircle(
        center: Offset(pinCenterX, pinTop + pinRadius),
        radius: pinRadius,
      ),
      0,
      3.14159 * 2, // Full circle
    );
    
    // Add pointed bottom (teardrop tail)
    pinPath.moveTo(pinCenterX - (isMobile ? 6 : 8), pinBottomY);
    pinPath.lineTo(pinCenterX + (isMobile ? 6 : 8), pinBottomY);
    pinPath.lineTo(pinCenterX, pinPointY);
    pinPath.close();

    // Add subtle shadow to pin
    final Paint pinShadow = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMobile ? 2 : 3);
    canvas.drawPath(pinPath.shift(const Offset(1, 2)), pinShadow);

    // Draw pin body with gradient-like effect
    final Paint pinBody = Paint()..color = pinColor;
    canvas.drawPath(pinPath, pinBody);

    // Draw pin outline
    final Paint pinOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isMobile ? 1.5 : 2.0
      ..color = isDark ? Colors.white.withAlpha(180) : Colors.black.withAlpha(100);
    canvas.drawPath(pinPath, pinOutline);

    // Draw inner circle for capacity or status indicator
    final double innerRadius = isMobile ? 13.0 : 16.0;
    final Offset innerCenter = Offset(pinCenterX, pinTop + pinRadius);
    
    // Inner circle background
    final Paint innerBg = Paint()..color = pinAccent;
    canvas.drawCircle(innerCenter, innerRadius, innerBg);
    
    // Inner circle border
    final Paint innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = isDark ? Colors.white.withAlpha(200) : Colors.white.withAlpha(180);
    canvas.drawCircle(innerCenter, innerRadius, innerBorder);

    // Draw capacity text or status icon
    final String capText = (capacity != null && capacity > 0) ? capacity.toString() : '';
    if (capText.isNotEmpty) {
      final ui.ParagraphBuilder cpb = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w800,
        ),
      )..pushStyle(ui.TextStyle(color: Colors.white))
       ..addText(capText);
      final ui.Paragraph capPara = cpb.build()
        ..layout(ui.ParagraphConstraints(width: innerRadius * 2));
      canvas.drawParagraph(capPara, Offset(innerCenter.dx - innerRadius, innerCenter.dy - capPara.height / 2));
    } else {
      // Draw a small dot or icon in the center
      final Paint centerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(innerCenter, isMobile ? 3 : 4, centerDot);
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(canvasWidth, canvasHeight);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes);
  }

  // Get Google landmark pin color based on driver status
  Color _getGoogleLandmarkPinColor(String driverId, bool isDark) {
    // Use a consistent color scheme similar to Google's landmark pins
    // Different colors for different driver IDs to make them distinguishable
    final int hash = driverId.hashCode;
    final List<Color> googleColors = [
      const Color(0xFF4285F4), // Google Blue
      const Color(0xFF34A853), // Google Green  
      const Color(0xFFEA4335), // Google Red
      const Color(0xFFFBBC04), // Google Yellow
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
    ];
    return googleColors[hash.abs() % googleColors.length];
  }

  // Get accent color for the inner circle
  Color _getGoogleLandmarkPinAccent(String driverId, bool isDark) {
    final Color baseColor = _getGoogleLandmarkPinColor(driverId, isDark);
    return Color.lerp(baseColor, Colors.white, 0.3) ?? baseColor;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
          return LayoutBuilder(
            builder: (ctx, constraints) {
              // Auto-switch to dialog when viewport becomes wider
              if (constraints.maxWidth >= 700) {
                Future.microtask(() {
                  if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                  _presentDriverDetailsModal(driver);
                });
                return const SizedBox.shrink();
              }
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: _buildDriverDetailsContent(driver, isDark, maxWidth: constraints.maxWidth, isMobile: isMobile),
                ),
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          return LayoutBuilder(
            builder: (ctx, constraints) {
              // Auto-switch to bottom sheet if viewport becomes small
              if (constraints.maxWidth < 700) {
                // Close this dialog and open bottom sheet
                Future.microtask(() {
                  if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                  _presentDriverDetailsModal(driver);
                });
                return const SizedBox.shrink();
              }

              final double vw = constraints.maxWidth;
              final double vh = MediaQuery.of(ctx).size.height;
              final double maxDialogWidth = (
                vw >= 1400 ? vw * 0.6 :
                vw >= 1100 ? vw * 0.7 :
                vw >= 900 ? vw * 0.8 : vw
              ).clamp(360.0, 920.0);
              final double maxDialogHeight = (vh * 0.85).clamp(420.0, vh * 0.9);
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
                    child: _buildDriverDetailsContent(driver, isDark, maxWidth: maxDialogWidth, isMobile: isMobile),
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Widget _buildDriverDetailsContent(Map<String, dynamic> driver, bool isDark, {double? maxWidth, bool isMobile = false}) {
    final Color textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF121212);
    final String driverName = driver['full_name']?.toString() ?? 'N/A';
    final String driverId = driver['driver_id']?.toString() ?? 'N/A';
    final String vehicleId = driver['vehicle_id']?.toString() ?? 'N/A';
    final String plateNumber = driver['plate_number']?.toString() ?? 'N/A';
    final String routeId = driver['route_id']?.toString() ?? 'N/A';
    final String passengerCapacity = (driver['passenger_capacity'] ?? driver['capacity'])?.toString() ?? 'N/A';
    final String sittingPassenger = (driver['sitting_passenger'])?.toString() ?? 'N/A';
    final String standingPassenger = (driver['standing_passenger'])?.toString() ?? 'N/A';
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
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

          // Info in symmetrical 2-column grid, including Status on the right
          LayoutBuilder(
            builder: (context, constraints) {
              final List<Widget> gridItems = [
                _infoChip('ID: $driverId', Icons.badge, statusColor, textColor, isDark, maxWidth: maxWidth),
                _infoChip('Vehicle: $vehicleId', Icons.directions_car, Palette.orangeColor, textColor, isDark, maxWidth: maxWidth),
                _infoChip('Plate: $plateNumber', Icons.credit_card, Palette.yellowColor, textColor, isDark, maxWidth: maxWidth),
                _infoChip('Route: $routeId', Icons.route, Palette.redColor, textColor, isDark, maxWidth: maxWidth),
                _infoChip('Capacity: $passengerCapacity', Icons.people, isDark ? Palette.darkInfo : Palette.lightInfo, textColor, isDark, maxWidth: maxWidth),
                _infoChip('Sitting: $sittingPassenger', Icons.event_seat, isDark ? Palette.darkSecondary : Palette.lightSecondary, textColor, isDark, maxWidth: maxWidth),
                _infoChip('Standing: $standingPassenger', Icons.accessibility_new, isDark ? Palette.darkInfo : Palette.lightInfo, textColor, isDark, maxWidth: maxWidth),
                _statusInfoChip(drivingStatus, statusColor, textColor),
              ];
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 6,
                mainAxisSpacing: 10,
                childAspectRatio: isMobile ? 4.0 : 6.0,
                children: gridItems,
              );
            },
          ),

          const SizedBox(height: 16),
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
                minimumSize: const Size(0, 60),
              ),
              child: const Text('Center on Driver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: accent.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 12, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
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

  Widget _statusInfoChip(String? drivingStatus, Color statusColor, Color textColor) {
    final String label = _capitalizeFirstLetter(drivingStatus ?? 'N/A');
    return Material(
      color: statusColor.withAlpha(24),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withAlpha(100), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: statusColor.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(_getStatusIcon(drivingStatus), size: 12, color: statusColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
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
