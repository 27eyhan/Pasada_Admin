import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'dart:convert';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/analytics_service.dart';
import 'package:pasada_admin_application/widgets/sync_progress_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FleetAnalyticsGraph extends StatefulWidget {
  final String? routeId;
  const FleetAnalyticsGraph({super.key, this.routeId});

  @override
  State<FleetAnalyticsGraph> createState() => _FleetAnalyticsGraphState();
}

class _FleetAnalyticsGraphState extends State<FleetAnalyticsGraph> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _loading = false;
  String? _error;
  List<double> _trafficSeries = const [];
  List<double> _predictedSeries = const [];
  List<Map<String, dynamic>> _routes = const [];
  String? _selectedRouteId; // local selection, defaults to widget.routeId
  
  // Synchronization state
  bool _isSyncing = false;
  String _syncStatus = '';
  double _syncProgress = 0.0;
  
  // Collection status state
  bool _collectionStatusLoading = false;
  Map<String, dynamic>? _collectionStatus;
  String? _collectionError;
  
  // Weekly processing state
  bool _isProcessingWeekly = false;
  String _weeklyProcessingStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchTraffic();
    _loadRoutes();
    _fetchCollectionStatus();
  }

  @override
  void didUpdateWidget(covariant FleetAnalyticsGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeId != widget.routeId) {
      setState(() {
        _selectedRouteId = widget.routeId;
      });
      _fetchPredictions();
    }
  }

  Future<void> _fetchTraffic() async {
    if (!_analyticsService.isConfigured) {
      setState(() {
        _error = 'API not configured';
      });
      return;
    }
    final String routeId =
        (_selectedRouteId != null && _selectedRouteId!.isNotEmpty)
            ? _selectedRouteId!
            : ((widget.routeId == null || widget.routeId!.isEmpty) ? '1' : widget.routeId!);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Try hybrid endpoint first (working with Bun migration)
      final hybrid = await _analyticsService.getHybridRouteAnalytics(routeId);
      if (hybrid.statusCode == 200) {
        final decoded = jsonDecode(hybrid.body);
        List<double> localSeries = [];
        if (decoded is Map && decoded['local'] is Map) {
          final localData = decoded['local'] as Map;
          // Parse from local.historicalData[].trafficDensity
          if (localData['historicalData'] is List) {
            for (final item in (localData['historicalData'] as List)) {
              if (item is Map && item['trafficDensity'] is num) {
                localSeries.add((item['trafficDensity'] as num).toDouble());
              }
            }
          }
        }
        // Process historical data to get meaningful weekly representation
        List<double> week = [];
        if (localSeries.isNotEmpty) {
          // Group data by actual day of week using timestamps
          final dailyAverages = <int, List<double>>{};
          if (decoded is Map && decoded['local'] is Map) {
            final localData = decoded['local'] as Map;
            if (localData['historicalData'] is List) {
              final historicalData = localData['historicalData'] as List;
              for (int i = 0; i < historicalData.length && i < localSeries.length; i++) {
                final item = historicalData[i];
                if (item is Map && item['timestamp'] is String) {
                  try {
                    final timestamp = DateTime.parse(item['timestamp']);
                    final dayOfWeek = timestamp.weekday % 7; // Convert to 0-6 (Sunday=0)
                    dailyAverages.putIfAbsent(dayOfWeek, () => []).add(localSeries[i]);
                  } catch (e) {
                    // Fallback to simple grouping if timestamp parsing fails
                    final dayOfWeek = i % 7;
                    dailyAverages.putIfAbsent(dayOfWeek, () => []).add(localSeries[i]);
                  }
                }
              }
            }
          }
          
          // Calculate average for each day of the week (Sunday=0 to Saturday=6)
          for (int day = 0; day < 7; day++) {
            if (dailyAverages.containsKey(day) && dailyAverages[day]!.isNotEmpty) {
              final avg = dailyAverages[day]!.reduce((a, b) => a + b) / dailyAverages[day]!.length;
              week.add(avg);
            } else {
              // Use the last available data point or generate fallback
              week.add(localSeries.isNotEmpty ? localSeries.last : 0.5);
            }
          }
        } else {
          week = _generateWeeklyTraffic(routeId);
        }
        setState(() {
          _trafficSeries = week;
          _loading = false;
        });
        return; // done
      }

      // Fallback: external traffic summary (also working with Bun)
      final external = await _analyticsService.getExternalRouteTrafficSummary(routeId, days: 7);
      if (external.statusCode == 200) {
        final decoded = jsonDecode(external.body);
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          // Generate mock weekly data based on average traffic density
          final avgDensity = (data['avg_traffic_density'] as num?)?.toDouble() ?? 0.5;
          final week = List.generate(7, (index) => avgDensity + (index % 2 == 0 ? 0.1 : -0.1));
          setState(() {
            _trafficSeries = week;
            _loading = false;
          });
          return;
        }
      }

      // Final fallback: local-only endpoint (may fail with Bun migration)
      final local = await _analyticsService.getLocalRouteAnalytics(routeId);
      if (local.statusCode != 200) {
        setState(() {
          _error = 'Failed to fetch route analytics (${local.statusCode}). All endpoints unavailable.';
          _loading = false;
        });
        return;
      }
      final decoded = jsonDecode(local.body);
      List<double> values = [];
      if (decoded is Map && decoded['historicalData'] is List) {
        for (final item in (decoded['historicalData'] as List)) {
          if (item is Map && item['trafficDensity'] is num) {
            values.add((item['trafficDensity'] as num).toDouble());
          }
        }
      }
      final List<double> week = values.length >= 7
          ? values.sublist(values.length - 7)
          : (values.isNotEmpty ? values : _generateWeeklyTraffic(routeId));
      setState(() {
        _trafficSeries = week;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch traffic';
        _loading = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('official_routes')
          .select('officialroute_id, route_name')
          .order('officialroute_id');

      final List<Map<String, dynamic>> routes =
          (response as List).cast<Map<String, dynamic>>();

      setState(() {
        _routes = routes;
        // Initialize local selected route id
        _selectedRouteId = widget.routeId ??
            (routes.isNotEmpty ? routes.first['officialroute_id']?.toString() : null);
      });
      _fetchPredictions();
    } catch (e) {
      // Non-fatal; keep dropdown empty
    }
  }

  Future<void> _fetchPredictions() async {
    if (!_analyticsService.isConfigured) {
      return;
    }
    final String routeId =
        (_selectedRouteId != null && _selectedRouteId!.isNotEmpty)
            ? _selectedRouteId!
            : ((widget.routeId == null || widget.routeId!.isEmpty) ? '1' : widget.routeId!);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Try hybrid predictions first (working with Bun migration)
      final hybrid = await _analyticsService.getHybridRouteAnalytics(routeId);
      if (hybrid.statusCode == 200) {
        final decoded = jsonDecode(hybrid.body);
        List<double> preds = [];
        if (decoded is Map) {
          // Try local predictions first
          if (decoded['local'] is Map && decoded['local']['predictions'] is List) {
            for (final item in (decoded['local']['predictions'] as List)) {
              if (item is Map && item['predictedDensity'] is num) {
                preds.add((item['predictedDensity'] as num).toDouble());
              }
            }
          }
          // Fallback to external predictions if local is empty
          if (preds.isEmpty && decoded['external'] is Map && decoded['external']['predictions'] is List) {
            for (final item in (decoded['external']['predictions'] as List)) {
              if (item is Map && item['predictedDensity'] is num) {
                preds.add((item['predictedDensity'] as num).toDouble());
              }
            }
          }
        }
        setState(() {
          _predictedSeries = preds.take(7).toList();
          _loading = false;
        });
        return;
      }

      // Fallback to external predictions endpoint
      final resp = await _analyticsService.getExternalRoutePredictions(routeId);
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Failed to fetch predictions (${resp.statusCode})';
          _loading = false;
        });
        return;
      }
      final decoded = jsonDecode(resp.body);
      List<double> preds = [];
      if (decoded is Map && decoded['data'] is List) {
        for (final item in (decoded['data'] as List)) {
          if (item is Map && item['predictedDensity'] is num) {
            preds.add((item['predictedDensity'] as num).toDouble());
          }
        }
      }
      setState(() {
        _predictedSeries = preds.take(7).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch predictions';
        _loading = false;
      });
    }
  }

  // Stub data generator for a week (Mon-Sun) - route-specific

  List<double> _generateWeeklyTraffic([String? routeId]) {
    // Generate route-specific traffic patterns based on route ID
    final int routeSeed = int.tryParse(routeId ?? '1') ?? 1;
    final List<List<double>> basePatterns = [
      [35.0, 28.0, 40.0, 42.0, 38.0, 30.0, 25.0], // Route 1: Peak on Thu
      [42.0, 35.0, 38.0, 45.0, 40.0, 32.0, 28.0], // Route 2: Higher overall, peak on Thu
      [28.0, 32.0, 35.0, 38.0, 42.0, 35.0, 30.0], // Route 3: Gradual increase, peak on Fri
      [30.0, 25.0, 35.0, 40.0, 38.0, 32.0, 28.0], // Route 4: Mid-week peak
      [38.0, 42.0, 35.0, 30.0, 45.0, 40.0, 35.0], // Route 5: Weekend heavy
    ];
    
    // Use route ID to select pattern, cycling through available patterns
    final int patternIndex = (routeSeed - 1) % basePatterns.length;
    final List<double> basePattern = basePatterns[patternIndex];
    
    // Add some variation based on route ID to make each route unique
    final double variation = (routeSeed % 10) * 0.5; // 0-4.5 variation
    return basePattern.map((value) => (value + variation).clamp(0.0, 100.0)).toList();
  }

  // Very simple prediction: repeat last delta trend for next 7 days
  List<double> _predictNextWeek(List<double> currentWeek) {
    if (currentWeek.isEmpty) return [];
    final List<double> prediction = [];
    final double avgDelta = _averageDelta(currentWeek);
    double last = currentWeek.last;
    for (int i = 0; i < 7; i++) {
      last += avgDelta * 0.8; // dampened extrapolation
      prediction.add(last);
    }
    return prediction;
  }

  double _averageDelta(List<double> series) {
    if (series.length < 2) return 0;
    double sum = 0;
    for (int i = 1; i < series.length; i++) {
      sum += (series[i] - series[i - 1]);
    }
    return sum / (series.length - 1);
  }

  Future<void> _synchronizeData() async {
    if (!_analyticsService.isConfigured) {
      _showErrorSnackBar('API not configured');
      return;
    }

    try {
      // Step 1: Check QuestDB Status
      setState(() {
        _syncProgress = 0.2;
        _syncStatus = 'Checking QuestDB connection...';
      });
      
      final questDbStatus = await _analyticsService.checkQuestDBStatus();
      if (questDbStatus.statusCode != 200) {
        throw Exception('QuestDB is not available (${questDbStatus.statusCode})');
      }

      // Step 2: Check Migration Status
      setState(() {
        _syncProgress = 0.4;
        _syncStatus = 'Verifying migration service...';
      });
      
      final migrationStatus = await _analyticsService.checkMigrationStatus();
      if (migrationStatus.statusCode != 200) {
        throw Exception('Migration service is not ready (${migrationStatus.statusCode})');
      }

      // Step 3: Execute Migration
      setState(() {
        _syncProgress = 0.8;
        _syncStatus = 'Executing data migration...';
      });
      
      final migrationResult = await _analyticsService.executeMigration();
      if (migrationResult.statusCode != 200) {
        throw Exception('Migration failed: ${migrationResult.body}');
      }

      // Step 4: Refresh data after successful migration
      setState(() {
        _syncProgress = 0.9;
        _syncStatus = 'Refreshing data...';
      });
      
      await _fetchTraffic();
      await _fetchPredictions();

      setState(() {
        _syncProgress = 1.0;
        _syncStatus = 'Synchronization completed successfully!';
      });

      _showSuccessSnackBar('Data synchronized successfully');
    } catch (e) {
      setState(() {
        _syncStatus = 'Synchronization failed: $e';
        _syncProgress = 0.0;
      });
      _showErrorSnackBar('Synchronization failed: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Palette.lightError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _fetchCollectionStatus() async {
    if (!_analyticsService.isConfigured) {
      return;
    }
    
    setState(() {
      _collectionStatusLoading = true;
      _collectionError = null;
    });
    
    try {
      final response = await _analyticsService.getDailyCollectionStatus();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _collectionStatus = decoded;
          _collectionStatusLoading = false;
        });
      } else {
        setState(() {
          _collectionError = 'Failed to fetch collection status (${response.statusCode})';
          _collectionStatusLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _collectionError = 'Failed to fetch collection status: $e';
        _collectionStatusLoading = false;
      });
    }
  }

  Future<void> _processWeeklyAnalytics({int? weekOffset}) async {
    if (!_analyticsService.isConfigured) {
      _showErrorSnackBar('API not configured');
      return;
    }

    setState(() {
      _isProcessingWeekly = true;
      _weeklyProcessingStatus = 'Processing weekly analytics...';
    });

    try {
      final response = weekOffset != null 
          ? await _analyticsService.processWeeklyAnalyticsWithOffset(weekOffset)
          : await _analyticsService.processWeeklyAnalytics();
      
      if (response.statusCode == 200) {
        setState(() {
          _weeklyProcessingStatus = 'Weekly analytics processed successfully!';
        });
        _showSuccessSnackBar('Weekly analytics processed successfully');
        
        // Refresh data after processing
        await _fetchTraffic();
        await _fetchPredictions();
        await _fetchCollectionStatus();
      } else {
        setState(() {
          _weeklyProcessingStatus = 'Failed to process weekly analytics (${response.statusCode})';
        });
        _showErrorSnackBar('Failed to process weekly analytics: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _weeklyProcessingStatus = 'Failed to process weekly analytics: $e';
      });
      _showErrorSnackBar('Failed to process weekly analytics: $e');
    } finally {
      setState(() {
        _isProcessingWeekly = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<double> baseSeries = _trafficSeries.isNotEmpty ? _trafficSeries : _generateWeeklyTraffic(_selectedRouteId);
    final List<double> predictionSeries =
        _predictedSeries.isNotEmpty ? _predictedSeries : _predictNextWeek(baseSeries);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        border: Border.all(
          color: isDark
              ? Palette.darkBorder.withValues(alpha: 77)
              : Palette.lightBorder.withValues(alpha: 77),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Traffic',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              const Spacer(),
              if (_routes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _RouteDropdown(
                    routes: _routes,
                    value: _selectedRouteId,
                    onChanged: (val) {
                      setState(() {
                        _selectedRouteId = val;
                      });
                      _fetchTraffic();
                      _fetchPredictions();
                    },
                  ),
                ),
              // Collection status and sync controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Collection status indicator
                  if (_collectionStatusLoading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Palette.lightPrimary),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                  ] else if (_collectionStatus != null) ...[
                    _CollectionStatusIndicator(
                      collectionStatus: _collectionStatus!,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8.0),
                  ],
                  if (_isSyncing || _syncStatus.isNotEmpty || _isProcessingWeekly || _weeklyProcessingStatus.isNotEmpty) ...[
                    // Status text (sync or weekly processing)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _isProcessingWeekly ? _weeklyProcessingStatus : _syncStatus,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0,
                          color: _isProcessingWeekly
                              ? Palette.lightPrimary
                              : _syncProgress == 1.0 
                                  ? Colors.green
                                  : _syncProgress > 0.0 
                                      ? Palette.lightPrimary
                                      : isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Progress indicator
                    if ((_syncProgress > 0.0 && _syncProgress < 1.0) || _isProcessingWeekly)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: _isProcessingWeekly ? null : _syncProgress,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Palette.lightPrimary),
                        ),
                      ),
                    const SizedBox(width: 8.0),
                  ],
                  // Weekly processing button
                  IconButton(
                    tooltip: _isProcessingWeekly ? 'Processing...' : 'Process weekly analytics',
                    onPressed: (_loading || _isSyncing || _isProcessingWeekly)
                        ? null
                        : () => _processWeeklyAnalytics(),
                    icon: Icon(
                      _isProcessingWeekly ? Icons.hourglass_empty : Icons.analytics,
                      size: 18,
                      color: _isProcessingWeekly 
                          ? Palette.lightPrimary
                          : isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                  // Sync button
                  IconButton(
                    tooltip: _isSyncing ? 'Synchronizing...' : 'Synchronize data',
                    onPressed: (_loading || _isSyncing || _isProcessingWeekly)
                        ? null
                        : () {
                            setState(() {
                              _isSyncing = true;
                              _syncStatus = 'Starting synchronization...';
                              _syncProgress = 0.0;
                            });
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => SyncProgressDialog(
                                title: 'Synchronizing Traffic Data',
                                syncFunction: _synchronizeData,
                                onComplete: () {
                                  setState(() {
                                    _isSyncing = false;
                                    _syncStatus = 'Last synced: ${DateTime.now().toString().substring(11, 19)}';
                                  });
                                  // Refresh collection status after sync
                                  _fetchCollectionStatus();
                                },
                                onError: () {
                                  setState(() {
                                    _isSyncing = false;
                                    _syncStatus = 'Sync failed';
                                  });
                                },
                              ),
                            );
                          },
                    icon: Icon(
                      _isSyncing ? Icons.sync : Icons.sync,
                      size: 18,
                      color: _isSyncing 
                          ? Palette.lightPrimary
                          : isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              // Metric dropdown removed (traffic-only)
            ],
          ),
          const SizedBox(height: 12.0),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _error!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  color: Palette.lightError,
                ),
              ),
            ),
          if (_collectionError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Collection Status: $_collectionError',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  color: Palette.lightError,
                ),
              ),
            ),
          _Legend(isDark: isDark),
          const SizedBox(height: 8.0),
          SizedBox(
            height: 160,
            child: _loading
                ? Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : _MiniLineChart(
                    currentWeek: baseSeries,
                    nextWeek: predictionSeries,
                    isDark: isDark,
                  ),
          ),
          const SizedBox(height: 8.0),
          _WeekAxis(isDark: isDark),
        ],
      ),
    );
  }
}

// Metric dropdown removed

class _RouteDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> routes;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _RouteDropdown({required this.routes, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;
    final double dropdownWidth = isSmallMobile
        ? screenWidth * 0.46
        : (isMobile ? screenWidth * 0.4 : 220);
    
    return SizedBox(
      width: dropdownWidth,
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 8.0 : (isMobile ? 10.0 : 12.0),
        vertical: isSmallMobile ? 4.0 : (isMobile ? 6.0 : 8.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            'Route',
            style: TextStyle(
              fontSize: isSmallMobile ? 12.0 : (isMobile ? 13.0 : 14.0),
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              fontFamily: 'Inter',
            ),
          ),
          style: TextStyle(
            fontSize: isSmallMobile ? 12.0 : (isMobile ? 13.0 : 14.0),
            color: isDark ? Palette.darkText : Palette.lightText,
            fontFamily: 'Inter',
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: isSmallMobile ? 16.0 : (isMobile ? 18.0 : 20.0),
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
          dropdownColor: isDark ? Palette.darkCard : Palette.lightCard,
            isExpanded: true,
            isDense: false,
            itemHeight: isMobile ? 44.0 : 40.0,
            menuMaxHeight: isMobile ? 320.0 : 400.0,
            borderRadius: BorderRadius.circular(8.0),
            selectedItemBuilder: (context) {
              return routes.map((r) {
                final String id = r['officialroute_id']?.toString() ?? '';
                final String name = r['route_name']?.toString() ?? 'Route $id';
                final String display = isSmallMobile ? name : '$name (ID: $id)';
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    display,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12.0 : (isMobile ? 13.0 : 14.0),
                      color: isDark ? Palette.darkText : Palette.lightText,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              }).toList();
            },
          items: routes.map((r) {
            final String id = r['officialroute_id']?.toString() ?? '';
            final String name = r['route_name']?.toString() ?? 'Route $id';
            return DropdownMenuItem<String>(
              value: id,
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallMobile ? 4.0 : (isMobile ? 6.0 : 8.0),
                ),
                child: Text(
                  isSmallMobile ? name : '$name (ID: $id)',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 11.0 : (isMobile ? 12.0 : 13.0),
                    color: isDark ? Palette.darkText : Palette.lightText,
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final bool isDark;
  const _Legend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
          color: Palette.lightPrimary,
          label: 'This week',
          isDark: isDark,
          dashed: false,
        ),
        const SizedBox(width: 12.0),
        _LegendItem(
          color: Palette.lightWarning,
          label: 'Next week (predicted)',
          isDark: isDark,
          dashed: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  final bool dashed;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
    required this.dashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// Minimal custom painter line chart to avoid external dependencies.
class _MiniLineChart extends StatelessWidget {
  final List<double> currentWeek;
  final List<double> nextWeek;
  final bool isDark;
  const _MiniLineChart({
    required this.currentWeek,
    required this.nextWeek,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniLineChartPainter(
        currentWeek: currentWeek,
        nextWeek: nextWeek,
        isDark: isDark,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<double> currentWeek;
  final List<double> nextWeek;
  final bool isDark;
  _MiniLineChartPainter({
    required this.currentWeek,
    required this.nextWeek,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layout margins for y-axis labels and right padding
    const double leftMargin = 40.0;
    const double rightMargin = 8.0;
    final double chartLeft = leftMargin;
    final double chartRight = size.width - rightMargin;
    final double chartWidth = (chartRight - chartLeft).clamp(1.0, double.infinity);

    final Color gridColor = (isDark ? Palette.darkBorder : Palette.lightBorder).withValues(alpha: 51);
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle horizontal grid lines (and leave space on the left for labels)
    const int gridLines = 4; // results in 5 ticks (0..4)

    // Combine series to compute global min/max for scaling
    final List<double> combined = [...currentWeek, ...nextWeek];
    double minVal = combined.isEmpty ? 0 : combined.reduce((a, b) => a < b ? a : b);
    double maxVal = combined.isEmpty ? 1 : combined.reduce((a, b) => a > b ? a : b);
    if (minVal == maxVal) {
      minVal -= 1;
      maxVal += 1;
    }

    Path pathFor(List<double> series, double xStart, double xEnd) {
      final Path p = Path();
      if (series.isEmpty) return p;
      final double dx = (xEnd - xStart) / (series.length - 1);
      for (int i = 0; i < series.length; i++) {
        final double x = xStart + dx * i;
        final double t = (series[i] - minVal) / (maxVal - minVal);
        final double y = size.height - t * size.height;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p;
    }

    // Draw horizontal grid lines with Y-axis labels
    for (int i = 0; i <= gridLines; i++) {
      final double y = size.height * (i / gridLines);
      // Grid line
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      // Axis tick value
      final double valueAtTick = maxVal - (maxVal - minVal) * (i / gridLines);
      final String label;
      if (maxVal <= 1.0) {
        label = '${(valueAtTick * 100).round()}%';
      } else if ((maxVal - minVal) < 5) {
        label = valueAtTick.toStringAsFixed(1);
      } else {
        label = valueAtTick.round().toString();
      }

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftMargin - 6);

      tp.paint(canvas, Offset(leftMargin - tp.width - 6, y - tp.height / 2));
    }

    // Draw Y axis line
    canvas.drawLine(Offset(chartLeft, 0), Offset(chartLeft, size.height), gridPaint);

    // Current week occupies left half, next week occupies right half within chart area
    final double leftHalfEnd = chartLeft + chartWidth * 0.48;
    final double rightHalfStart = chartLeft + chartWidth * 0.52;
    final Path currentPath = pathFor(currentWeek, chartLeft, leftHalfEnd);
    final Path nextPath = pathFor(nextWeek, rightHalfStart, chartRight);

    final Paint currentPaint = Paint()
      ..color = Palette.lightPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint nextPaint = Paint()
      ..color = Palette.lightWarning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Draw current week
    canvas.drawPath(currentPath, currentPaint);

    // Draw predicted week as dashed line
    _drawDashedPath(canvas, nextPath, nextPaint, dashWidth: 6, dashGap: 6);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      {required double dashWidth, required double dashGap}) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double nextDistance = distance + dashWidth;
        final Path extractPath = metric.extractPath(
          distance,
          nextDistance.clamp(0, metric.length),
        );
        canvas.drawPath(extractPath, paint);
        distance = nextDistance + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) {
    return oldDelegate.currentWeek != currentWeek ||
        oldDelegate.nextWeek != nextWeek ||
        oldDelegate.isDark != isDark;
  }
}

class _WeekAxis extends StatelessWidget {
  final bool isDark;
  const _WeekAxis({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labels.length, (i) {
        final String text = labels[i];
        return Expanded(
          child: Align(
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CollectionStatusIndicator extends StatelessWidget {
  final Map<String, dynamic> collectionStatus;
  final bool isDark;
  
  const _CollectionStatusIndicator({
    required this.collectionStatus,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Parse collection status
    final bool isCollected = collectionStatus['isCollected'] ?? false;
    final String? lastCollectionDate = collectionStatus['lastCollectionDate'];
    final int routesWithData = collectionStatus['routesWithData'] ?? 0;
    final int totalRoutes = collectionStatus['totalRoutes'] ?? 0;
    
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isCollected) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Fresh';
    } else {
      statusColor = Palette.lightWarning;
      statusIcon = Icons.warning;
      statusText = 'Stale';
    }
    
    return Tooltip(
      message: _buildTooltipMessage(isCollected, lastCollectionDate, routesWithData, totalRoutes),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4.0),
          Text(
            statusText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.0,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  String _buildTooltipMessage(bool isCollected, String? lastCollectionDate, int routesWithData, int totalRoutes) {
    final buffer = StringBuffer();
    
    if (isCollected) {
      buffer.write('Data is fresh');
    } else {
      buffer.write('Data may be stale');
    }
    
    if (lastCollectionDate != null) {
      buffer.write('\nLast collection: $lastCollectionDate');
    }
    
    buffer.write('\nRoutes with data: $routesWithData/$totalRoutes');
    
    return buffer.toString();
  }
}



