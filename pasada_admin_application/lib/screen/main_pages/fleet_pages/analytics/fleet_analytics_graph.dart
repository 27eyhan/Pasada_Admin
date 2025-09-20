import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'dart:convert';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/analytics_service.dart';
import 'package:pasada_admin_application/widgets/sync_progress_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resend-like compact analytics card with a dropdown and weekly line chart.
/// - Modes: Traffic and Bookings
/// - Shows a 7-day week series with simple predictive extension for next week (dashed)
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
  bool _usingHybrid = true;
  
  // Synchronization state
  bool _isSyncing = false;
  String _syncStatus = '';
  double _syncProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchTraffic();
    _loadRoutes();
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
      if (_usingHybrid) {
        final hybrid = await _analyticsService.getHybridRouteAnalytics(routeId);
        if (hybrid.statusCode == 200) {
          final decoded = jsonDecode(hybrid.body);
          List<double> localSeries = [];
          if (decoded is Map && decoded['data'] is Map) {
            final data = decoded['data'] as Map;
            // Parse from data.historicalData[].trafficDensity
            if (data['historicalData'] is List) {
              for (final item in (data['historicalData'] as List)) {
                if (item is Map && item['trafficDensity'] is num) {
                  localSeries.add((item['trafficDensity'] as num).toDouble());
                }
              }
            }
          }
          // Use the last 7 points from historical data
          final List<double> week = localSeries.length >= 7
              ? localSeries.sublist(localSeries.length - 7)
              : (localSeries.isNotEmpty ? localSeries : _generateWeeklyTraffic());
          setState(() {
            _trafficSeries = week;
            _loading = false;
          });
          return; // done
        } else {
          // fall back
          setState(() {
            _usingHybrid = false;
          });
        }
      }

      // Fallback: local-only endpoint
      final local = await _analyticsService.getLocalRouteAnalytics(routeId);
      if (local.statusCode != 200) {
        setState(() {
          _error = 'Failed to fetch route analytics (${local.statusCode})';
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
          : (values.isNotEmpty ? values : _generateWeeklyTraffic());
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
      // Prefer hybrid predictions if available
      if (_usingHybrid) {
        final hybrid = await _analyticsService.getHybridRouteAnalytics(routeId);
        if (hybrid.statusCode == 200) {
          final decoded = jsonDecode(hybrid.body);
          List<double> preds = [];
          if (decoded is Map && decoded['data'] is Map) {
            final data = decoded['data'] as Map;
            if (data['predictions'] is List) {
              for (final item in (data['predictions'] as List)) {
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
        } else {
          setState(() {
            _usingHybrid = false;
          });
        }
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

  // Stub data generator for a week (Mon-Sun)

  List<double> _generateWeeklyTraffic() {
    // Example base values representing traffic density on a route
    return [35, 28, 40, 42, 38, 30, 25];
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<double> baseSeries = _trafficSeries.isNotEmpty ? _trafficSeries : _generateWeeklyTraffic();
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
                      _fetchPredictions();
                    },
                  ),
                ),
              // Synchronize button with status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSyncing || _syncStatus.isNotEmpty) ...[
                    // Sync status text
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _syncStatus,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.0,
                          color: _syncProgress == 1.0 
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
                    if (_syncProgress > 0.0 && _syncProgress < 1.0)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: _syncProgress,
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Palette.lightPrimary),
                        ),
                      ),
                    const SizedBox(width: 8.0),
                  ],
                  // Sync button
                  IconButton(
                    tooltip: _isSyncing ? 'Synchronizing...' : 'Synchronize data',
                    onPressed: (_loading || _isSyncing)
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.lightBorder.withValues(alpha: 77)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: const Text('Route'),
          items: routes.map((r) {
            final String id = r['officialroute_id']?.toString() ?? '';
            final String name = r['route_name']?.toString() ?? 'Route $id';
            return DropdownMenuItem<String>(
              value: id,
              child: Text('$name (ID: $id)'),
            );
          }).toList(),
          onChanged: onChanged,
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



