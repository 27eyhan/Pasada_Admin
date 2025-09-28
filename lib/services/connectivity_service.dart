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
    // Check if we have any network connection
    final hasNetworkConnection = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
    
    if (hasNetworkConnection) {
      // Test actual internet connectivity
      _testInternetConnectivity();
    } else {
      _isConnected = false;
      _isSlowConnection = false;
      _connectionSpeed = 0.0;
      notifyListeners();
    }
  }
  
  Future<void> _testInternetConnectivity() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      
      // Test with a simple, reliable endpoint
      final request = await client.getUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();
      
      client.close();
      
      if (response.statusCode == 200) {
        _isConnected = true;
        // Now test speed
        _testConnectionSpeed();
      } else {
        _isConnected = false;
        _isSlowConnection = false;
        _connectionSpeed = 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Internet connectivity test failed: $e');
      _isConnected = false;
      _isSlowConnection = false;
      _connectionSpeed = 0.0;
      notifyListeners();
    }
  }
  
  Future<void> _testConnectionSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Test with multiple endpoints for better reliability
      final testUrls = [
        'https://httpbin.org/bytes/1024',
        'https://www.google.com/favicon.ico',
        'https://httpbin.org/bytes/512'
      ];
      
      double totalSpeed = 0.0;
      int successfulTests = 0;
      
      for (final url in testUrls) {
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 8);
          
          final request = await client.getUrl(Uri.parse(url));
          final response = await request.close();
          
          if (response.statusCode == 200) {
            final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
            if (durationInSeconds > 0) {
              // Calculate speed in Mbps
              // 1KB = 8 kilobits = 0.008 megabits
              final speedInMbps = (8.0 * 0.001) / durationInSeconds;
              totalSpeed += speedInMbps;
              successfulTests++;
            }
          }
          
          client.close();
          stopwatch.reset();
          stopwatch.start();
        } catch (e) {
          debugPrint('Speed test failed for $url: $e');
          continue;
        }
      }
      
      stopwatch.stop();
      
      if (successfulTests > 0) {
        _connectionSpeed = totalSpeed / successfulTests;
        _isSlowConnection = _connectionSpeed < _slowConnectionThreshold;
        
        debugPrint('Connection speed test: ${_connectionSpeed.toStringAsFixed(2)} Mbps (${successfulTests} tests)');
        notifyListeners();
      } else {
        _isSlowConnection = true;
        _connectionSpeed = 0.0;
        notifyListeners();
      }
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
    debugPrint('Manual speed test initiated');
    await _testConnectionSpeed();
  }
  
  // Force a complete connectivity refresh
  Future<void> refreshConnectivity() async {
    debugPrint('Refreshing connectivity status...');
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('Error refreshing connectivity: $e');
    }
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
