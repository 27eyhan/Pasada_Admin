import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:pasada_admin_application/services/analytics_service.dart';
import 'package:provider/provider.dart';
// import removed; base URL handled in service

class BookingFrequencyGraph extends StatefulWidget {
  final int days;
  const BookingFrequencyGraph({super.key, this.days = 14});

  @override
  State<BookingFrequencyGraph> createState() => _BookingFrequencyGraphState();
}

class _BookingFrequencyGraphState extends State<BookingFrequencyGraph> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _loading = false;
  String? _error;
  List<double> _history = const [];
  List<double> _forecast = const [];
  String _source = 'live';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_analyticsService.isConfigured) {
      setState(() => _error = 'API not configured');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _analyticsService.getBookingFrequency(days: widget.days);
      if (resp.statusCode == 404) {
        // Fallback to persisted sources via service
        final daily = await _analyticsService.getBookingFrequencyDaily(days: widget.days);
        final latestForecast = await _analyticsService.getLatestBookingFrequencyForecast();
        if (daily.statusCode == 200) {
          final decodedDaily = jsonDecode(daily.body);
          final decodedForecast = latestForecast.statusCode == 200 ? jsonDecode(latestForecast.body) : null;
          return _parseAndSet(decodedDaily, decodedForecast);
        }
        setState(() {
          _error = 'Bookings endpoints not found (404). Live and persisted unavailable.';
          _loading = false;
        });
        return;
      }
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'Failed to fetch bookings (${resp.statusCode}): ${resp.body}';
          _loading = false;
        });
        return;
      }
      final decoded = jsonDecode(resp.body);
      List<double> history = [];
      List<double> forecast = [];
      if (decoded is Map && decoded['data'] is Map) {
        final data = decoded['data'] as Map;
        if (data['history'] is List) {
          for (final item in (data['history'] as List)) {
            if (item is Map && item['count'] is num) {
              history.add((item['count'] as num).toDouble());
            }
          }
        }
        if (data['forecast'] is List) {
          for (final item in (data['forecast'] as List)) {
            if (item is Map && item['predictedCount'] is num) {
              forecast.add((item['predictedCount'] as num).toDouble());
            }
          }
        }
      }

      // Display last 7 of history and next 7 of forecast
      final List<double> lastWeek = history.length >= 7
          ? history.sublist(history.length - 7)
          : history;
      final List<double> nextWeek = forecast.take(7).toList();

      setState(() {
        _history = lastWeek;
        _forecast = nextWeek;
        _source = 'live';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings: $e';
        _loading = false;
      });
    }
  }

  // Removed debug URL composition

  // Removed alternate path probing

  void _parseAndSet(dynamic decodedDaily, dynamic decodedForecast) {
    List<double> history = [];
    List<double> forecast = [];
    if (decodedDaily is Map && decodedDaily['data'] is List) {
      for (final item in (decodedDaily['data'] as List)) {
        if (item is Map && item['count'] is num) {
          history.add((item['count'] as num).toDouble());
        }
      }
    }
    if (decodedForecast is Map && decodedForecast['data'] is List) {
      for (final item in (decodedForecast['data'] as List)) {
        if (item is Map && item['predictedCount'] is num) {
          forecast.add((item['predictedCount'] as num).toDouble());
        }
      }
    }

    final List<double> lastWeek = history.length >= 7 ? history.sublist(history.length - 7) : history;
    final List<double> nextWeek = forecast.take(7).toList();

    setState(() {
      _history = lastWeek;
      _forecast = nextWeek;
      _source = 'persisted';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final List<double> baseSeries = _history.isNotEmpty ? _history : [0, 0, 0, 0, 0, 0, 0];
    final List<double> predictionSeries = _forecast.isNotEmpty ? _forecast : [0, 0, 0, 0, 0, 0, 0];

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
                'Bookings',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              const Spacer(),
              if (_source == 'persisted')
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    'source: QuestDB',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.0,
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                ),
              // Removed debug URL text
              IconButton(
                tooltip: 'Persist daily',
                onPressed: _loading
                    ? null
                    : () async {
                        try {
                          await _analyticsService.persistBookingFrequencyDaily(days: widget.days);
                        } catch (_) {}
                      },
                icon: Icon(Icons.save_alt, size: 18, color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
              ),
              IconButton(
                tooltip: 'Persist forecast',
                onPressed: _loading
                    ? null
                    : () async {
                        try {
                          await _analyticsService.persistBookingFrequencyForecast(days: widget.days);
                        } catch (_) {}
                      },
                icon: Icon(Icons.trending_up, size: 18, color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
              ),
              // Synchronize button
              IconButton(
                tooltip: 'Synchronize data',
                onPressed: _loading
                    ? null
                    : () async {
                        // TODO: Implement synchronize function
                        print('Synchronize booking frequency data');
                      },
                icon: Icon(
                  Icons.sync,
                  size: 18,
                  color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                ),
              ),
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
          Row(
            children: const [
              _LegendItem(color: Palette.lightPrimary, label: 'Last 7 days', dashed: false),
              SizedBox(width: 12.0),
              _LegendItem(color: Palette.lightWarning, label: 'Next 7 (forecast)', dashed: true),
            ],
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            height: 160,
            child: _loading
                ? Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : _MiniLineChart(currentWeek: baseSeries, nextWeek: predictionSeries, isDark: isDark),
          ),
          const SizedBox(height: 8.0),
          _WeekAxis(isDark: isDark),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendItem({required this.color, required this.label, required this.dashed});

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
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            color: Palette.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  final List<double> currentWeek;
  final List<double> nextWeek;
  final bool isDark;
  const _MiniLineChart({required this.currentWeek, required this.nextWeek, required this.isDark});

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
  _MiniLineChartPainter({required this.currentWeek, required this.nextWeek, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
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

    const int gridLines = 4;

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

    for (int i = 0; i <= gridLines; i++) {
      final double y = size.height * (i / gridLines);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final double valueAtTick = maxVal - (maxVal - minVal) * (i / gridLines);
      final String label = valueAtTick.round().toString();

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

    canvas.drawLine(Offset(chartLeft, 0), Offset(chartLeft, size.height), gridPaint);

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

    canvas.drawPath(currentPath, currentPaint);
    _drawDashedPath(canvas, nextPath, nextPaint, dashWidth: 6, dashGap: 6);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, {required double dashWidth, required double dashGap}) {
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


