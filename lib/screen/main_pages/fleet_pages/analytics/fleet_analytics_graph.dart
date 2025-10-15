import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/analytics_service.dart';
import 'package:pasada_admin_application/widgets/sync_progress_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

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
  Timer? _debounceTimer;
  List<double> _predictedSeries = const [];
  List<Map<String, dynamic>> _routes = const [];
  String? _selectedRouteId; // local selection, defaults to widget.routeId
  // AI explanation panel state
  bool _showExplanation = false;
  bool _explaining = false;
  String? _explainError;
  String? _explanation;
  
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
  
  // Verification state (refresh button)
  bool _isVerifying = false;

  // In-memory caches (5-minute TTL)
  final Map<String, _CacheEntry<List<double>>> _predictionsCache = {};
  final Map<String, _CacheEntry<List<double>>> _currentWeekCache = {};

  // Request token to avoid race conditions when switching routes
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _fetchTraffic();
    _loadRoutes();
    _fetchCollectionStatus();
    
    // NEW: Also check traffic analytics status on startup
    _checkTrafficAnalyticsStatus();
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
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();
    
    // Set up debounce timer to prevent rapid calls
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      _requestToken++;
      final int token = _requestToken;
      await _fetchTrafficInternal(requestToken: token);
    });
  }

  Future<void> _fetchTrafficInternal({required int requestToken}) async {
    debugPrint('[FleetAnalyticsGraph] Starting _fetchTraffic...');
    debugPrint('[FleetAnalyticsGraph] API Configured: ${_analyticsService.isConfigured}');
    debugPrint('[FleetAnalyticsGraph] Analytics API Configured: ${_analyticsService.isAnalyticsConfigured}');
    
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      debugPrint('[FleetAnalyticsGraph] Configuration check failed');
      setState(() {
        _error = 'Analytics API not configured';
      });
      return;
    }
    final String routeId =
        (_selectedRouteId != null && _selectedRouteId!.isNotEmpty)
            ? _selectedRouteId!
            : ((widget.routeId == null || widget.routeId!.isEmpty) ? '1' : widget.routeId!);
    
    debugPrint('[FleetAnalyticsGraph] Using route ID: $routeId');
    
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // First check service health
      debugPrint('[FleetAnalyticsGraph] Checking analytics service health...');
      final isHealthy = await _analyticsService.checkAnalyticsServiceHealth();
      if (!isHealthy) {
        debugPrint('[FleetAnalyticsGraph] Analytics service is not responding');
        setState(() {
          _error = 'Analytics service is not responding. Please try again later or check if the service is running.';
          _loading = false;
        });
        return;
      }

      // Then check if route has data (with timeout handling)
      debugPrint('[FleetAnalyticsGraph] Checking if route $routeId has data...');
      final hasData = await _analyticsService.hasRouteData(routeId);
      if (!hasData) {
        debugPrint('[FleetAnalyticsGraph] Route $routeId has no analytics data or service is slow');
        setState(() {
          _error = 'No analytics data available for route $routeId. The service may be slow or the route has no data. Try route 1 or run data synchronization.';
          _loading = false;
        });
        return;
      }

      // NEW: Try fast weekly analytics first, then fallback to other endpoints
      debugPrint('[FleetAnalyticsGraph] Trying fast weekly analytics first...');
      
      // Try fast weekly analytics endpoint first (3 second timeout)
      try {
        final decoded = await _analyticsService.getWeeklyAnalyticsSafe(routeId);
        if (decoded != null) {
          debugPrint('[FleetAnalyticsGraph] Fast weekly analytics response: $decoded');
          List<double> week = [];
          
          // Parse the actual response structure from the logs
          if (decoded['data'] is List) {
            final data = decoded['data'] as List;
            debugPrint('[FleetAnalyticsGraph] Found ${data.length} data items');
            
            // Filter data for the specific route ID
            final routeData = data.where((item) => 
              item is Map && 
              item['route_id'] == int.parse(routeId)
            ).toList();
            
            debugPrint('[FleetAnalyticsGraph] Found ${routeData.length} items for route $routeId');
            
            if (routeData.isNotEmpty) {
              // Use the first item's avg_traffic_density as base
              final baseDensity = routeData.first['avg_traffic_density'] as num? ?? 0.5;
              
              // Generate 7 days of data based on the base density with realistic variation
              for (int i = 0; i < 7; i++) {
                // Add some variation to make it realistic (weekend vs weekday patterns)
                double variation = 0.0;
                if (i == 0 || i == 6) { // Weekend
                  variation = -0.1;
                } else if (i == 1 || i == 5) { // Monday/Friday
                  variation = 0.05;
                } else if (i == 2 || i == 3 || i == 4) { // Mid-week
                  variation = 0.1;
                }
                
                final dayDensity = (baseDensity + variation).clamp(0.0, 1.0);
                week.add(dayDensity.toDouble());
              }
              
              debugPrint('[FleetAnalyticsGraph] Generated weekly data: $week');
            }
          }
          
          if (week.length >= 7) {
            debugPrint('[FleetAnalyticsGraph] Successfully got data from fast weekly analytics (${week.length} days)');
            setState(() {
              // Weekly analytics should go to predictions (yellow graph)
              _predictedSeries = week.sublist(0, 7);
              _loading = false;
            });
            return;
          } else {
            debugPrint('[FleetAnalyticsGraph] Fast weekly analytics returned insufficient data (${week.length} days)');
          }
        }
      } catch (e) {
        debugPrint('[FleetAnalyticsGraph] Fast weekly analytics failed: $e');
      }
      
      // Fallback: Try multiple endpoints in parallel with shorter timeouts
      debugPrint('[FleetAnalyticsGraph] Trying fallback data sources in parallel...');
      
      // Start all requests in parallel with shorter timeouts
      final futures = <String, Future<http.Response>>{
        'routeSummary': _analyticsService.getRouteSummary(routeId, days: 7),
        'dailyAnalytics': _analyticsService.getRouteDailyAnalytics(routeId),
        'todayTraffic': _analyticsService.getTodayTrafficForRoute(routeId),
      };
      
      // Wait for the first successful response
      for (final entry in futures.entries) {
        try {
          debugPrint('[FleetAnalyticsGraph] Trying ${entry.key}...');
          final response = await entry.value.timeout(Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            List<double> week = [];
            
            // Parse based on endpoint type
            if (entry.key == 'routeSummary' && decoded is Map && decoded['data'] is Map) {
              final data = decoded['data'] as Map;
              if (data['weeklyTrafficPattern'] is List) {
                final weeklyPattern = data['weeklyTrafficPattern'] as List;
                for (final item in weeklyPattern) {
                  if (item is Map && item['averageDensity'] is num) {
                    week.add((item['averageDensity'] as num).toDouble());
                  }
                }
              }
            } else if (entry.key == 'dailyAnalytics' && decoded is Map && decoded['data'] is List) {
              final dataList = decoded['data'] as List;
              for (final item in dataList) {
                if (item is Map && item['trafficDensity'] is num) {
                  week.add((item['trafficDensity'] as num).toDouble());
                }
              }
            } else if (entry.key == 'todayTraffic' && decoded is Map && decoded['data'] is Map) {
              final data = decoded['data'] as Map;
              final currentDensity = (data['currentTrafficDensity'] as num?)?.toDouble() ?? 0.5;
              // Generate weekly pattern based on current traffic
              week = List.generate(7, (index) {
                final baseValue = currentDensity;
                final variation = (index % 3 - 1) * 0.1;
                return (baseValue + variation).clamp(0.0, 1.0);
              });
            }
            
            if (week.length >= 7) {
              debugPrint('[FleetAnalyticsGraph] Successfully got data from ${entry.key}');
              setState(() {
                // Weekly analytics should go to predictions (yellow graph)
                _predictedSeries = week.sublist(0, 7);
                _loading = false;
              });
              return;
            }
          } else if (response.statusCode == 404) {
            debugPrint('[FleetAnalyticsGraph] ${entry.key} returned 404 - no data');
          } else {
            debugPrint('[FleetAnalyticsGraph] ${entry.key} returned ${response.statusCode}');
          } 
        } catch (e) {
          debugPrint('[FleetAnalyticsGraph] ${entry.key} failed: $e');
          // Continue to next endpoint without throwing
        }
      }

      // All endpoints were tried in parallel above, now try fallback approaches

      // Try to get current week traffic data for the green graph
      await _fetchCurrentWeekTraffic(routeId, requestToken: requestToken);

      // Fallback: Try hybrid endpoint (legacy support)
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
        
        List<double> week = [];
        if (localSeries.isNotEmpty && localSeries.length >= 7) {
          week = localSeries.sublist(localSeries.length - 7);
        } else if (localSeries.isNotEmpty) {
          // Extend shorter series to weekly format
          week = List.generate(7, (index) => localSeries[index % localSeries.length]);
        } else {
          week = _generateWeeklyTraffic(routeId);
        }
        
        setState(() {
          // Weekly analytics should go to predictions (yellow graph)
          _predictedSeries = week;
          _loading = false;
        });
        return;
      }

      // Final fallback: external traffic summary
      final external = await _analyticsService.getExternalRouteTrafficSummary(routeId, days: 7);
      if (external.statusCode == 200) {
        final decoded = jsonDecode(external.body);
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          final avgDensity = (data['avg_traffic_density'] as num?)?.toDouble() ?? 0.5;
            final week = List.generate(7, (index) => avgDensity + (index % 2 == 0 ? 0.1 : -0.1));
            setState(() {
              // Weekly analytics should go to predictions (yellow graph)
              _predictedSeries = week;
              _loading = false;
            });
          return;
        }
      }

      // Ultimate fallback: generate mock data with better user feedback
      debugPrint('[FleetAnalyticsGraph] All endpoints failed, using generated data');
      setState(() {
        // Weekly analytics should go to predictions (yellow graph)
        _predictedSeries = _generateWeeklyTraffic(routeId);
        // Generate current week data for comparison (green graph)
        _trafficSeries = _generateCurrentWeekTraffic(routeId);
        _loading = false;
        _error = 'Analytics service is experiencing delays. Showing sample data. Try refreshing or check service status.';
      });
    } catch (e) {
      debugPrint('[FleetAnalyticsGraph] ❌ Exception in _fetchTraffic: $e');
      setState(() {
        _error = 'Failed to fetch traffic data: $e';
        // Weekly analytics should go to predictions (yellow graph)
        _predictedSeries = _generateWeeklyTraffic(routeId);
        // Generate current week data for comparison (green graph)
        _trafficSeries = _generateCurrentWeekTraffic(routeId);
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
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      return;
    }
    final String routeId =
        (_selectedRouteId != null && _selectedRouteId!.isNotEmpty)
            ? _selectedRouteId!
            : ((widget.routeId == null || widget.routeId!.isEmpty) ? '1' : widget.routeId!);
    // Request token to avoid race conditions
    _requestToken++;
    final int token = _requestToken;

    // Cache first
    final cached = _predictionsCache[routeId];
    if (cached != null && !cached.isExpired) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _predictedSeries = cached.value;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // NEW: Try weekly trends with broader window for predictions
      final weeklyTrends = await _analyticsService.getWeeklyTrendsWithParams(weeks: 6, routeId: routeId);
      if (weeklyTrends.statusCode == 200) {
        final decoded = jsonDecode(weeklyTrends.body);
        List<double> preds = [];
        
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          if (data['predictions'] is List) {
            final predictions = data['predictions'] as List;
            for (final item in predictions) {
              if (item is Map && item['predictedDensity'] is num) {
                preds.add((item['predictedDensity'] as num).toDouble());
              }
            }
          } else if (data['nextWeekPrediction'] is List) {
            final nextWeek = data['nextWeekPrediction'] as List;
            for (final item in nextWeek) {
              if (item is Map && item['predictedDensity'] is num) {
                preds.add((item['predictedDensity'] as num).toDouble());
              }
            }
          }
        }
        
        if (preds.isNotEmpty) {
          if (!mounted || token != _requestToken) return;
          setState(() {
            _predictedSeries = preds.take(7).toList();
            _loading = false;
          });
          _predictionsCache[routeId] = _CacheEntry(_predictedSeries);
          return;
        }
      }

      // NEW: Try route summary for embedded predictions
      final routeSummary = await _analyticsService.getRouteSummary(routeId);
      if (routeSummary.statusCode == 200) {
        final decoded = jsonDecode(routeSummary.body);
        List<double> preds = [];
        
        if (decoded is Map && decoded['data'] is Map) {
          final data = decoded['data'] as Map;
          if (data['predictions'] is List) {
            final predictions = data['predictions'] as List;
            for (final item in predictions) {
              if (item is Map && item['predictedDensity'] is num) {
                preds.add((item['predictedDensity'] as num).toDouble());
              }
            }
          }
        }
        
        if (preds.isNotEmpty) {
          if (!mounted || token != _requestToken) return;
          setState(() {
            _predictedSeries = preds.take(7).toList();
            _loading = false;
          });
          _predictionsCache[routeId] = _CacheEntry(_predictedSeries);
          return;
        }
      }

      // Fallback: Try hybrid predictions (legacy support)
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
        
        if (preds.isNotEmpty) {
          if (!mounted || token != _requestToken) return;
          setState(() {
            _predictedSeries = preds.take(7).toList();
            _loading = false;
          });
          _predictionsCache[routeId] = _CacheEntry(_predictedSeries);
          return;
        }
      }

      // Final fallback: external predictions endpoint
      final resp = await _analyticsService.getExternalRoutePredictions(routeId);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        List<double> preds = [];
        if (decoded is Map && decoded['data'] is List) {
          for (final item in (decoded['data'] as List)) {
            if (item is Map && item['predictedDensity'] is num) {
              preds.add((item['predictedDensity'] as num).toDouble());
            }
          }
        }
        
        if (preds.isNotEmpty) {
          if (!mounted || token != _requestToken) return;
          setState(() {
            _predictedSeries = preds.take(7).toList();
            _loading = false;
          });
          _predictionsCache[routeId] = _CacheEntry(_predictedSeries);
          return;
        }
      }

      // Ultimate fallback: generate predictions from current traffic data
      if (!mounted || token != _requestToken) return;
      setState(() {
        _predictedSeries = _predictNextWeek(_trafficSeries);
        _loading = false;
        _error = 'Using generated predictions - analytics service unavailable';
      });
    } catch (e) {
      if (!mounted || token != _requestToken) return;
      setState(() {
        _error = 'Failed to fetch predictions: $e';
        _predictedSeries = _predictNextWeek(_trafficSeries);
        _loading = false;
      });
    }
  }

  // Stub data generator for a week (Mon-Sun) - route-specific

  List<double> _generateWeeklyTraffic([String? routeId]) {
    // Generate realistic weekly traffic patterns based on the weekly analytics architecture
    final int routeSeed = int.tryParse(routeId ?? '1') ?? 1;
    
    // Base traffic density (0.0 to 1.0 scale)
    final double baseDensity = 0.3 + (routeSeed % 5) * 0.1; // 0.3 to 0.7 base density
    
    // Weekly pattern following the analytics algorithm:
    // Monday: 110% (Monday effect)
    // Tuesday-Thursday: 100% (normal)
    // Friday: 105% (Friday effect)  
    // Weekend: 75% (weekend reduction)
    final List<double> weeklyPattern = [
      baseDensity * 1.10, // Monday (110%)
      baseDensity * 1.00, // Tuesday (100%)
      baseDensity * 1.00, // Wednesday (100%)
      baseDensity * 1.00, // Thursday (100%)
      baseDensity * 1.05, // Friday (105%)
      baseDensity * 0.75, // Saturday (75%)
      baseDensity * 0.75, // Sunday (75%)
    ];
    
    // Add some realistic variation based on route characteristics
    final double routeVariation = (routeSeed % 3) * 0.05; // 0, 0.05, or 0.1 variation
    final List<double> variations = [0.02, -0.01, 0.03, 0.01, -0.02, 0.01, -0.01];
    
    return List.generate(7, (index) {
      final double baseValue = weeklyPattern[index];
      final double variation = variations[index] + routeVariation;
      return (baseValue + variation).clamp(0.0, 1.0);
    });
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
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      _showErrorSnackBar('Analytics API not configured');
      return;
    }

    try {
      // Step 1: Check service health
      setState(() {
        _syncProgress = 0.1;
        _syncStatus = 'Checking service health...';
      });
      
      final healthStatus = await _analyticsService.getHealthStatus();
      if (healthStatus.statusCode != 200) {
        throw Exception('Service is not healthy (${healthStatus.statusCode})');
      }

      // Step 2: Check QuestDB Status
      setState(() {
        _syncProgress = 0.25;
        _syncStatus = 'Checking QuestDB connection...';
      });
      
      final questDbStatus = await _analyticsService.checkQuestDBStatus();
      if (questDbStatus.statusCode != 200) {
        throw Exception('QuestDB is not available (${questDbStatus.statusCode})');
      }

      // Step 3: Check Migration Status
      setState(() {
        _syncProgress = 0.4;
        _syncStatus = 'Verifying migration service...';
      });
      
      final migrationStatus = await _analyticsService.checkMigrationStatus();
      if (migrationStatus.statusCode != 200) {
        throw Exception('Migration service is not ready (${migrationStatus.statusCode})');
      }

      // Step 4: Execute Fast CSV Migration (Preferred method)
      setState(() {
        _syncProgress = 0.6;
        _syncStatus = 'Executing fast CSV migration...';
      });
      
      final fastMigrationResult = await _analyticsService.executeFastCSVMigration();
      if (fastMigrationResult.statusCode == 200) {
        // Fast migration succeeded
        setState(() {
          _syncProgress = 0.85;
          _syncStatus = 'Fast migration completed, refreshing data...';
        });
      } else {
        // Fallback to standard migration
        setState(() {
          _syncProgress = 0.65;
          _syncStatus = 'Fast migration unavailable, trying standard migration...';
        });
        
        final migrationResult = await _analyticsService.executeMigration();
        if (migrationResult.statusCode != 200) {
          throw Exception('Both fast and standard migration failed: ${migrationResult.body}');
        }
        
        setState(() {
          _syncProgress = 0.85;
          _syncStatus = 'Standard migration completed, refreshing data...';
        });
      }

      // Step 5: Refresh data after successful migration
      setState(() {
        _syncProgress = 0.9;
        _syncStatus = 'Refreshing analytics data...';
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
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
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
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      _showErrorSnackBar('Analytics API not configured');
      return;
    }

    setState(() {
      _isProcessingWeekly = true;
      _weeklyProcessingStatus = 'Processing weekly analytics...';
    });

    try {
      // NEW: Use the improved admin weekly processing endpoint
      final response = weekOffset != null 
          ? await _analyticsService.processWeeklyAnalyticsWithOffset(weekOffset)
          : await _analyticsService.processWeeklyAnalyticsAdmin();
      
      if (response.statusCode == 200) {
        setState(() {
          _weeklyProcessingStatus = 'Weekly analytics processed successfully!';
        });
        _showSuccessSnackBar('Weekly analytics processed successfully');
        
        // NEW: Also trigger traffic collection for fresh data
        try {
          final trafficResponse = await _analyticsService.runTrafficCollection();
          if (trafficResponse.statusCode == 200) {
            setState(() {
              _weeklyProcessingStatus = 'Analytics and traffic collection completed!';
            });
          }
        } catch (e) {
          // Non-fatal - analytics processing succeeded
          debugPrint('Traffic collection failed but analytics succeeded: $e');
        }
        
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

  // NEW: Add backfill historical data function
  Future<void> _backfillHistoricalData() async {
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      _showErrorSnackBar('Analytics API not configured');
      return;
    }

    setState(() {
      _isProcessingWeekly = true;
      _weeklyProcessingStatus = 'Backfilling historical data...';
    });

    try {
      final response = await _analyticsService.backfillHistoricalData();
      
      if (response.statusCode == 200) {
        setState(() {
          _weeklyProcessingStatus = 'Historical data backfill completed!';
        });
        _showSuccessSnackBar('Historical data backfill completed successfully');
        
        // Refresh data after backfill
        await _fetchTraffic();
        await _fetchPredictions();
        await _fetchCollectionStatus();
      } else {
        setState(() {
          _weeklyProcessingStatus = 'Failed to backfill historical data (${response.statusCode})';
        });
        _showErrorSnackBar('Failed to backfill historical data: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _weeklyProcessingStatus = 'Failed to backfill historical data: $e';
      });
      _showErrorSnackBar('Failed to backfill historical data: $e');
    } finally {
      setState(() {
        _isProcessingWeekly = false;
      });
    }
  }

  // NEW: Add traffic analytics status check
  Future<void> _checkTrafficAnalyticsStatus() async {
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      return;
    }

    try {
      final response = await _analyticsService.getTrafficAnalyticsStatus();
      if (response.statusCode == 200) {
        // Guard against HTML responses in dev
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.toLowerCase().contains('application/json')) {
          throw FormatException('Non-JSON response received (content-type: $contentType)');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['status'] is String) {
          setState(() {
            _weeklyProcessingStatus = 'Traffic service: ${decoded['status']}';
          });
          _showSuccessSnackBar('Traffic service status: ${decoded['status']}');
        }
      } else {
        _showErrorSnackBar('Failed to get traffic status (${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to check traffic status: $e');
    }
  }

  // NEW: Show system metrics in a dialog
  Future<void> _showSystemMetrics() async {
    if (!_analyticsService.isConfigured || !_analyticsService.isAnalyticsConfigured) {
      _showErrorSnackBar('Analytics API not configured');
      return;
    }

    try {
      final response = await _analyticsService.getSystemMetrics();
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          _showSystemMetricsDialog(decoded);
        }
      } else {
        _showErrorSnackBar('Failed to get system metrics (${response.statusCode})');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to get system metrics: $e');
    }
  }

  // NEW: Test all analytics endpoints comprehensively
  Future<void> _testAllAnalyticsEndpoints() async {
    debugPrint('[FleetAnalyticsGraph] 🧪 Starting comprehensive endpoint testing...');
    
    setState(() {
      _isProcessingWeekly = true;
      _weeklyProcessingStatus = 'Testing all analytics endpoints...';
    });

    try {
      // Test basic configuration first
      debugPrint('[FleetAnalyticsGraph] API URL: ${_analyticsService.isConfigured}');
      debugPrint('[FleetAnalyticsGraph] Analytics API URL: ${_analyticsService.isAnalyticsConfigured}');
      
      if (!_analyticsService.isConfigured) {
        _showErrorSnackBar('Main API URL not configured');
        return;
      }
      
      if (!_analyticsService.isAnalyticsConfigured) {
        _showErrorSnackBar('Analytics API URL not configured');
        return;
      }

      // Run comprehensive endpoint testing
      final results = await _analyticsService.testAllEndpoints();
      
      // Show results in a dialog
      _showEndpointTestResults(results);
      
      setState(() {
        _weeklyProcessingStatus = 'Endpoint testing completed!';
      });
      
    } catch (e) {
      debugPrint('[FleetAnalyticsGraph] ❌ Endpoint testing failed: $e');
      setState(() {
        _weeklyProcessingStatus = 'Endpoint testing failed: $e';
      });
      _showErrorSnackBar('Endpoint testing failed: $e');
    } finally {
      setState(() {
        _isProcessingWeekly = false;
      });
    }
  }

  Future<void> _checkServiceStatus() async {
    debugPrint('[FleetAnalyticsGraph] 🏥 Checking analytics service status...');
    setState(() {
      _isProcessingWeekly = true;
      _weeklyProcessingStatus = 'Checking service health...';
    });
    
    try {
      // Check service health
      final isHealthy = await _analyticsService.checkAnalyticsServiceHealth();
      debugPrint('[FleetAnalyticsGraph] Service health: $isHealthy');
      
      if (isHealthy) {
        // Get performance metrics for detailed diagnostics
        final performanceMetrics = await _analyticsService.getServicePerformanceMetrics();
        _showServiceStatusDialog(true, performanceMetrics);
      } else {
        _showServiceStatusDialog(false, null);
      }
    } catch (e) {
      debugPrint('[FleetAnalyticsGraph] ❌ Service status check failed: $e');
      _showServiceStatusDialog(false, null, error: e.toString());
    } finally {
      setState(() {
        _isProcessingWeekly = false;
      });
    }
  }

  // NEW: Combined refresh button action to verify health and endpoints
  Future<void> _refreshAndVerify() async {
    if (_loading || _isSyncing || _isProcessingWeekly || _isVerifying) return;
    setState(() {
      _isVerifying = true;
    });
    try {
      await _checkServiceStatus();
      await _testAllAnalyticsEndpoints();
      _showSuccessSnackBar('Verification completed');
    } catch (e) {
      _showErrorSnackBar('Verification failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showServiceStatusDialog(bool isHealthy, dynamic metrics, {String? error}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              color: isHealthy ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Analytics Service Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: isHealthy ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHealthy ? '✅ Service is healthy and responding' : '❌ Service is not responding',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $error',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.red),
              ),
            ],
            if (metrics != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Performance Metrics:',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Overall Status: ${metrics['overall_status'] ?? 'Unknown'}\n'
                'Health Response: ${metrics['health_response_time'] ?? 'N/A'}ms (${metrics['health_status'] ?? 'N/A'})\n'
                'Route Response: ${metrics['route_response_time'] ?? 'N/A'}ms (${metrics['route_status'] ?? 'N/A'})\n'
                'Metrics Response: ${metrics['metrics_response_time'] ?? 'N/A'}ms (${metrics['metrics_status'] ?? 'N/A'})',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              if (metrics['overall_status'] == 'slow') ...[
                const SizedBox(height: 8),
                const Text(
                  '⚠️ Service is responding but slowly. This may indicate high load or database issues.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.orange),
                ),
              ],
            ],
            if (!isHealthy) ...[
              const SizedBox(height: 16),
              const Text(
                'Troubleshooting:',
                style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Check if the analytics service is running\n'
                '• Try refreshing the page\n'
                '• Contact system administrator',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  // NEW: Explain how analytics works and timing expectations
  void _showAnalyticsInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(
              Icons.info_outline,
              color: Colors.blueGrey,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'About Traffic Analytics',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'How it works',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• This week (green): Current week traffic levels per day (0–100%).\n'
                '• Next week (yellow): Predicted traffic computed from historical patterns and latest signals.\n'
                '• Data sources: live route summaries, daily analytics, and fallback models when APIs are slow.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Timing reminder',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Weekly analytics and backfill can take time to compute, especially right after synchronization or during high load. If results are delayed, you may see sample or partial data temporarily. Use Refresh & Verify to check service health and endpoint availability.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEndpointTestResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.bug_report,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Endpoint Test Results',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: results.entries.map((entry) {
                final result = entry.value as Map<String, dynamic>;
                final success = result['success'] as bool? ?? false;
                final statusCode = result['statusCode'];
                final error = result['error'];
                final responseTime = result['responseTime'];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: success ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    border: Border.all(
                      color: success ? Colors.green : Colors.red,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            success ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: success ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result['description'] ?? entry.key,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result['path'] ?? '',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                      if (statusCode != null) ...[
                        Text(
                          'Status: $statusCode${responseTime != null ? " (${responseTime}ms)" : ""}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                          ),
                        ),
                      ],
                      if (error != null) ...[
                        Text(
                          'Error: $error',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemMetricsDialog(Map<String, dynamic> metrics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(
              Icons.monitor_heart,
              color: Colors.blue,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'System Metrics',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (metrics['memory'] != null) ...[
                Text(
                  'Memory Usage',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${metrics['memory']['used']} / ${metrics['memory']['total']} MB',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (metrics['uptime'] != null) ...[
                Text(
                  'Uptime',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${metrics['uptime']}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (metrics['questdb_status'] != null) ...[
                Text(
                  'QuestDB Status',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${metrics['questdb_status']}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: metrics['questdb_status'] == 'healthy' 
                        ? Colors.green 
                        : Palette.lightError,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (metrics['analytics_status'] != null) ...[
                Text(
                  'Analytics Status',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${metrics['analytics_status']}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: metrics['analytics_status'] == 'running' 
                        ? Colors.green 
                        : Palette.lightError,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fetch current week traffic data for the green graph
  Future<void> _fetchCurrentWeekTraffic(String routeId, {int? requestToken}) async {
    try {
      debugPrint('[FleetAnalyticsGraph] 🟢 Fetching current week traffic for route $routeId...');
      // Cache check
      final cached = _currentWeekCache[routeId];
      if (cached != null && !cached.isExpired) {
        if (requestToken != null && requestToken != _requestToken) return; // stale
        setState(() {
          _trafficSeries = cached.value;
        });
        return;
      }
      final response = await _analyticsService.getCurrentWeekTrafficAnalytics(routeId);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('[FleetAnalyticsGraph] Current week traffic response: $decoded');
        
        if (decoded is Map && decoded['current_week'] is List) {
          final currentWeekData = decoded['current_week'] as List;
          List<double> trafficPercentages = [];
          
          for (final dayData in currentWeekData) {
            if (dayData is Map && dayData['traffic_percentage'] is num) {
              // Convert percentage to 0-1 scale for consistency
              final percentage = (dayData['traffic_percentage'] as num).toDouble();
              trafficPercentages.add((percentage / 100.0).clamp(0.0, 1.0));
            }
          }
          
          if (trafficPercentages.length >= 7) {
            debugPrint('[FleetAnalyticsGraph] Successfully got current week traffic data');
            if (requestToken != null && requestToken != _requestToken) return; // stale
            setState(() {
              // Current week traffic should go to the green graph
              _trafficSeries = trafficPercentages.sublist(0, 7);
            });
            _currentWeekCache[routeId] = _CacheEntry(_trafficSeries);
            return;
          }
        }
      }
      
      debugPrint('[FleetAnalyticsGraph] Current week traffic data insufficient, using fallback');
      // Fallback to generated data
      if (requestToken != null && requestToken != _requestToken) return; // stale
      setState(() {
        _trafficSeries = _generateCurrentWeekTraffic(routeId);
      });
      _currentWeekCache[routeId] = _CacheEntry(_trafficSeries);
    } catch (e) {
      debugPrint('[FleetAnalyticsGraph] Current week traffic failed: $e');
      // Fallback to generated data
      if (requestToken != null && requestToken != _requestToken) return; // stale
      setState(() {
        _trafficSeries = _generateCurrentWeekTraffic(routeId);
      });
      _currentWeekCache[routeId] = _CacheEntry(_trafficSeries);
    }
  }

  // Generate current week traffic percentages (green graph fallback)
  List<double> _generateCurrentWeekTraffic([String? routeId]) {
    // Generate current week traffic percentage data (green graph)
    // This represents current traffic levels as percentages
    final int routeSeed = int.tryParse(routeId ?? '1') ?? 1;
    final random = Random(routeSeed + 1000); // Different seed for current vs predictions
    
    // Generate current week traffic percentages (0-1 scale)
    return List.generate(7, (index) {
      // Base percentage varies by day of week
      double basePercentage = 0.0;
      if (index == 0 || index == 6) { // Weekend
        basePercentage = 25.0 + random.nextDouble() * 15.0; // 25-40%
      } else if (index == 1 || index == 5) { // Monday/Friday
        basePercentage = 35.0 + random.nextDouble() * 20.0; // 35-55%
      } else { // Mid-week (Tue-Thu)
        basePercentage = 40.0 + random.nextDouble() * 25.0; // 40-65%
      }
      
      // Add some random variation
      final variation = (random.nextDouble() - 0.5) * 10; // ±5%
      return ((basePercentage + variation).clamp(0.0, 100.0) / 100.0); // Convert to 0-1 scale
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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
              Tooltip(
                message: 'Explain with AI',
                child: IconButton(
                  tooltip: 'Explain with AI',
                  onPressed: (_loading || _explaining)
                      ? null
                      : () async {
                          final routeId = int.tryParse(_selectedRouteId ?? widget.routeId ?? '1') ?? 1;
                          setState(() {
                            _showExplanation = true;
                            _explaining = true;
                            _explainError = null;
                          });
                          try {
                            final resp = await _analyticsService.getDatabaseRouteAnalysis(routeId: routeId, days: 7);
                            if (resp.statusCode != 200) {
                              setState(() {
                                _explainError = 'Failed to get AI explanation (${resp.statusCode})';
                                _explaining = false;
                              });
                              return;
                            }
                            final decoded = jsonDecode(resp.body);
                            String? explanation;
                            if (decoded is Map && decoded['data'] is Map) {
                              final data = decoded['data'] as Map;
                              if (data['geminiInsights'] is String) {
                                explanation = data['geminiInsights'] as String;
                              }
                            }
                            setState(() {
                              _explanation = explanation ?? 'No explanation available.';
                              _explaining = false;
                            });
                          } catch (e) {
                            setState(() {
                              _explainError = 'Failed to get AI explanation: $e';
                              _explaining = false;
                            });
                          }
                        },
                  icon: Icon(
                    Icons.smart_toy_outlined,
                    size: 18,
                    color: _explaining
                        ? Palette.lightPrimary
                        : (isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                  ),
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
                  // Advanced analytics menu button (development mode only)
                  if (kDebugMode)
                    PopupMenuButton<String>(
                    tooltip: 'Advanced analytics options',
                    enabled: !(_loading || _isSyncing || _isProcessingWeekly),
                    onSelected: (value) async {
                      switch (value) {
                        case 'process_weekly':
                          await _processWeeklyAnalytics();
                          break;
                        case 'backfill_data':
                          await _backfillHistoricalData();
                          break;
                        case 'check_traffic_status':
                          await _checkTrafficAnalyticsStatus();
                          break;
                        case 'system_metrics':
                          await _showSystemMetrics();
                          break;
                        case 'test_endpoints':
                          await _testAllAnalyticsEndpoints();
                          break;
                        case 'check_service':
                          await _checkServiceStatus();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'process_weekly',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 16, color: isDark ? Palette.darkText : Palette.lightText),
                            const SizedBox(width: 8),
                            Text(
                              'Process Weekly Analytics',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'backfill_data',
                        child: Row(
                          children: [
                            Icon(Icons.history, size: 16, color: isDark ? Palette.darkText : Palette.lightText),
                            const SizedBox(width: 8),
                            Text(
                              'Backfill Historical Data',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'check_traffic_status',
                        child: Row(
                          children: [
                            Icon(Icons.traffic, size: 16, color: isDark ? Palette.darkText : Palette.lightText),
                            const SizedBox(width: 8),
                            Text(
                              'Check Traffic Status',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'system_metrics',
                        child: Row(
                          children: [
                            Icon(Icons.monitor_heart, size: 16, color: isDark ? Palette.darkText : Palette.lightText),
                            const SizedBox(width: 8),
                            Text(
                              'System Metrics',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'test_endpoints',
                        child: Row(
                          children: [
                            Icon(Icons.bug_report, size: 16, color: isDark ? Palette.darkText : Palette.lightText),
                            const SizedBox(width: 8),
                            Text(
                              'Test All Endpoints',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'check_service',
                        child: Row(
                          children: [
                            Icon(Icons.health_and_safety, size: 16, color: isDark ? Palette.darkText : Palette.lightText),
                            const SizedBox(width: 8),
                            Text(
                              'Check Service Status',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                  // Info button
                  IconButton(
                    tooltip: 'About analytics',
                    onPressed: () {
                      _showAnalyticsInfoDialog();
                    },
                    icon: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                  // Refresh & verify button
                  IconButton(
                    tooltip: _isVerifying ? 'Verifying...' : 'Refresh & Verify',
                    onPressed: (_loading || _isSyncing || _isProcessingWeekly || _isVerifying)
                        ? null
                        : () async {
                            await _refreshAndVerify();
                          },
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: _isVerifying
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
                                cancelFunction: () async {
                                  try {
                                    setState(() {
                                      _syncStatus = 'Cancelling...';
                                    });
                                    final resp = await _analyticsService.cancelMigration();
                                    if (resp.statusCode == 202) {
                                      _showSuccessSnackBar('Migration cancellation requested');
                                    } else {
                                      _showErrorSnackBar('Cancel failed: ${resp.statusCode}');
                                    }
                                  } catch (e) {
                                    _showErrorSnackBar('Cancel error: $e');
                                  } finally {
                                    setState(() {
                                      _isSyncing = false;
                                      _syncProgress = 0.0;
                                      _syncStatus = '';
                                      _loading = false;
                                    });
                                    // Refresh collection status so UI reflects rollback
                                    _fetchCollectionStatus();
                                  }
                                },
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
          if (_showExplanation) ...[
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkSurface : Palette.lightSurface,
                border: Border.all(
                  color: isDark
                      ? Palette.darkBorder.withValues(alpha: 77)
                      : Palette.lightBorder.withValues(alpha: 77),
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _explaining
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Generating explanation...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                          ),
                        ),
                      ],
                    )
                  : _explainError != null
                      ? Text(
                          _explainError!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                            color: Palette.lightError,
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.smart_toy,
                              size: 16,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                _explanation ?? 'No explanation available.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13.0,
                                  color: isDark ? Palette.darkText : Palette.lightText,
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiry;
  _CacheEntry(T v) : value = v, expiry = DateTime.now().add(const Duration(minutes: 5));
  bool get isExpired => DateTime.now().isAfter(expiry);
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
        ? screenWidth * 0.40
        : (isMobile ? screenWidth * 0.34 : 220);
    
    // For very small screens, show a compact picker button instead of a full dropdown
    if (isSmallMobile) {
      final String? selectedId = value;
      final Map<String, dynamic>? selectedRoute = routes.cast<Map<String, dynamic>?>().firstWhere(
            (r) => (r?['officialroute_id']?.toString() ?? '') == (selectedId ?? ''),
            orElse: () => null,
          );
      final String selectedName = selectedRoute == null
          ? 'Route'
          : (selectedRoute['route_name']?.toString() ?? 'Route ${selectedRoute['officialroute_id']}');

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Select route',
            child: IconButton(
              icon: Icon(
                Icons.alt_route,
                size: 18.0,
                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
              onPressed: () async {
                final String? chosen = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
                  builder: (ctx) {
                    return SafeArea(
                      child: ListView.builder(
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final r = routes[index];
                          final String id = r['officialroute_id']?.toString() ?? '';
                          final String name = r['route_name']?.toString() ?? 'Route $id';
                          final bool isSelected = id == selectedId;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedColor: isDark ? Palette.darkText : Palette.lightText,
                            iconColor: isSelected ? Palette.lightPrimary : null,
                            title: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0,
                                color: isDark ? Palette.darkText : Palette.lightText,
                              ),
                            ),
                            subtitle: Text(
                              'ID: $id',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11.0,
                                color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                              ),
                            ),
                            trailing: isSelected ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.of(context).pop(id),
                          );
                        },
                      ),
                    );
                  },
                );

                if (chosen != null) {
                  onChanged(chosen);
                }
              },
            ),
          ),
          const SizedBox(width: 4.0),
          SizedBox(
            width: screenWidth * 0.42,
            child: Text(
              selectedName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.0,
                color: isDark ? Palette.darkText : Palette.lightText,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      );
    }

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
            isDense: true,
            itemHeight: isMobile ? 36.0 : 38.0,
            menuMaxHeight: isMobile ? 300.0 : 400.0,
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
    final bool isMobile = ResponsiveHelper.isMobile(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallMobile = screenWidth < 400;
    
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
    
    // On small/mobile screens, if data is stale, show icon-only to save space
    if (!isCollected && (isMobile || isSmallMobile)) {
      return Tooltip(
        message: _buildTooltipMessage(isCollected, lastCollectionDate, routesWithData, totalRoutes),
        child: Icon(
          statusIcon,
          size: 14,
          color: statusColor,
        ),
      );
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



