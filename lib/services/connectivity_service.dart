import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool _isSlowConnection = false;
  double _connectionSpeed = 0.0; // in Mbps
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isSlowConnection => _isSlowConnection;
  double get connectionSpeed => _connectionSpeed;
  
  // Connection quality thresholds
  static const double _slowConnectionThreshold = 1.0; // 1 Mbps
  static const double _verySlowConnectionThreshold = 0.5; // 0.5 Mbps
  
  void initialize() {
    _startConnectivityMonitoring();
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );
    
    // Initial connectivity check
    _checkInitialConnectivity();
  }
  
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
    }
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool wasConnected = _isConnected;
    final bool wasSlowConnection = _isSlowConnection;
    
    _isConnected = results.isNotEmpty && 
                   results.any((result) => result != ConnectivityResult.none);
    
    if (_isConnected) {
      _testConnectionSpeed();
    } else {
      _isSlowConnection = false;
      _connectionSpeed = 0.0;
    }
    
    // Notify listeners if connection status changed
    if (wasConnected != _isConnected || wasSlowConnection != _isSlowConnection) {
      notifyListeners();
    }
  }
  
  Future<void> _testConnectionSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Test with a small HTTP request to measure speed
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://httpbin.org/bytes/1024'));
      final response = await request.close();
      
      stopwatch.stop();
      
      if (response.statusCode == 200) {
        // Calculate speed in Mbps (1KB = 8 kilobits)
        final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
        final speedInMbps = (8.0 * 1.024) / durationInSeconds; // 1KB = 8.192 kilobits
        
        _connectionSpeed = speedInMbps;
        _isSlowConnection = speedInMbps < _slowConnectionThreshold;
        
        notifyListeners();
      }
      
      client.close();
    } catch (e) {
      debugPrint('Error testing connection speed: $e');
      // If speed test fails, assume slow connection
      _isSlowConnection = true;
      _connectionSpeed = 0.0;
      notifyListeners();
    }
  }
  
  // Manual speed test method
  Future<void> performSpeedTest() async {
    await _testConnectionSpeed();
  }
  
  // Get connection quality description
  String getConnectionQualityDescription() {
    if (!_isConnected) {
      return 'No internet connection';
    } else if (_connectionSpeed < _verySlowConnectionThreshold) {
      return 'Very slow connection (${_connectionSpeed.toStringAsFixed(1)} Mbps)';
    } else if (_isSlowConnection) {
      return 'Slow connection (${_connectionSpeed.toStringAsFixed(1)} Mbps)';
    } else {
      return 'Good connection (${_connectionSpeed.toStringAsFixed(1)} Mbps)';
    }
  }
  
  // Check if connection is very slow (for more prominent warnings)
  bool get isVerySlowConnection => 
      _isConnected && _connectionSpeed < _verySlowConnectionThreshold;
}
