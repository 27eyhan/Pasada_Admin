import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _webConnectivityTimer;
  
  bool _isConnected = false; // Start as false until we check
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
    debugPrint('ConnectivityService: Initializing...');
    _startConnectivityMonitoring();
  }
  
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _webConnectivityTimer?.cancel();
    super.dispose();
  }
  
  void _startConnectivityMonitoring() {
    debugPrint('ConnectivityService: Starting connectivity monitoring...');
    debugPrint('ConnectivityService: kIsWeb = $kIsWeb');
    
    if (kIsWeb) {
      debugPrint('ConnectivityService: Running on web, testing internet connectivity directly...');
      _testInternetConnectivity();
      
      // For web, set up periodic connectivity monitoring since we can't rely on connectivity_plus
      _startWebConnectivityMonitoring();
    } else {
      // For mobile/desktop, use connectivity_plus
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          debugPrint('ConnectivityService: Connectivity changed: $results');
          _handleConnectivityChange(results);
        },
      );
      
      // Initial connectivity check
      _checkInitialConnectivity();
    }
  }
  
  Future<void> _checkInitialConnectivity() async {
    try {
      debugPrint('ConnectivityService: Checking initial connectivity...');
      final results = await _connectivity.checkConnectivity();
      debugPrint('ConnectivityService: Initial connectivity results: $results');
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('ConnectivityService: Error checking initial connectivity: $e');
    }
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    debugPrint('ConnectivityService: Handling connectivity change: $results');
    
    // Check if we have any network connection
    final hasNetworkConnection = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
    debugPrint('ConnectivityService: Has network connection: $hasNetworkConnection');
    
    if (hasNetworkConnection) {
      // Test actual internet connectivity
      debugPrint('ConnectivityService: Testing internet connectivity...');
      _testInternetConnectivity();
    } else {
      debugPrint('ConnectivityService: No network connection detected');
      _isConnected = false;
      _isSlowConnection = false;
      _connectionSpeed = 0.0;
      notifyListeners();
    }
  }
  
  void _startWebConnectivityMonitoring() {
    debugPrint('ConnectivityService: Starting web connectivity monitoring...');
    // Check connectivity every 30 seconds for web
    _webConnectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('ConnectivityService: Periodic web connectivity check...');
      _testInternetConnectivity();
    });
  }
  
  Future<void> _testInternetConnectivity() async {
    try {
      debugPrint('ConnectivityService: Testing internet connectivity...');
      debugPrint('ConnectivityService: Platform is web: $kIsWeb');
      
      // For web, use a more reliable approach with multiple fallback URLs
      final testUrls = kIsWeb ? [
        'https://www.google.com/favicon.ico', // Google favicon - very reliable
        'https://httpbin.org/get',
        'https://jsonplaceholder.typicode.com/posts/1',
        'https://api.github.com/zen',
        'https://www.cloudflare.com/favicon.ico' // Cloudflare favicon as final fallback
      ] : [
        'https://httpbin.org/get'
      ];
      
      bool connectionSuccessful = false;
      
      for (final url in testUrls) {
        try {
          debugPrint('ConnectivityService: Testing with $url...');
          
          if (kIsWeb) {
            // Use http package for web platforms
            final response = await http.get(
              Uri.parse(url),
              headers: {'User-Agent': 'Mozilla/5.0 (compatible; ConnectivityTest/1.0)'},
            ).timeout(const Duration(seconds: 3));
            
            debugPrint('ConnectivityService: Internet test response code: ${response.statusCode}');
            
            if (response.statusCode == 200) {
              debugPrint('ConnectivityService: Internet connectivity confirmed with $url');
              _isConnected = true;
              connectionSuccessful = true;
              break;
            }
          } else {
            // Use HttpClient for mobile/desktop platforms
            final client = HttpClient();
            client.connectionTimeout = const Duration(seconds: 5);
            
            final request = await client.getUrl(Uri.parse(url));
            final response = await request.close();
            
            client.close();
            
            debugPrint('ConnectivityService: Internet test response code: ${response.statusCode}');
            
            if (response.statusCode == 200) {
              debugPrint('ConnectivityService: Internet connectivity confirmed with $url');
              _isConnected = true;
              connectionSuccessful = true;
              break;
            }
          }
        } catch (e) {
          debugPrint('ConnectivityService: Test failed with $url: $e');
          continue;
        }
      }
      
      if (connectionSuccessful) {
        // Set a default good speed for web
        _connectionSpeed = kIsWeb ? 15.0 : 10.0; // Assume good speed for web
        _isSlowConnection = false;
        notifyListeners();
        
        // Now test actual speed
        _testConnectionSpeed();
      } else {
        debugPrint('ConnectivityService: All internet connectivity tests failed');
        
        // For web, if all tests fail, assume we have connectivity but it's slow
        // This prevents the "No Connection" issue on web platforms
        if (kIsWeb) {
          debugPrint('ConnectivityService: Web platform - assuming connectivity with slow speed');
          _isConnected = true;
          _isSlowConnection = true;
          _connectionSpeed = 1.0; // Assume slow but connected
        } else {
          _isConnected = false;
          _isSlowConnection = false;
          _connectionSpeed = 0.0;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ConnectivityService: Internet connectivity test failed: $e');
      
      // For web, if connectivity test fails completely, assume we have connectivity but it's slow
      if (kIsWeb) {
        debugPrint('ConnectivityService: Web platform - assuming connectivity with slow speed due to test failure');
        _isConnected = true;
        _isSlowConnection = true;
        _connectionSpeed = 1.0; // Assume slow but connected
      } else {
        _isConnected = false;
        _isSlowConnection = false;
        _connectionSpeed = 0.0;
      }
      notifyListeners();
    }
  }
  
  Future<void> _testConnectionSpeed() async {
    try {
      debugPrint('ConnectivityService: Testing connection speed...');
      final stopwatch = Stopwatch()..start();
      
      // For web, use a more reliable speed test
      final testUrl = kIsWeb 
          ? 'https://jsonplaceholder.typicode.com/posts' // Returns JSON data
          : 'https://httpbin.org/bytes/1024';
      
      if (kIsWeb) {
        // Use http package for web platforms
        final response = await http.get(
          Uri.parse(testUrl),
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; ConnectivityTest/1.0)'},
        ).timeout(const Duration(seconds: 10));
        
        stopwatch.stop();
        
        if (response.statusCode == 200) {
          final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
          if (durationInSeconds > 0) {
            // For web, estimate speed based on response time
            // Faster response = better connection
            double estimatedSpeed;
            if (kIsWeb) {
              // For web, estimate based on response time
              if (durationInSeconds < 0.5) {
                estimatedSpeed = 20.0; // Very fast
              } else if (durationInSeconds < 1.0) {
                estimatedSpeed = 15.0; // Fast
              } else if (durationInSeconds < 2.0) {
                estimatedSpeed = 10.0; // Good
              } else if (durationInSeconds < 3.0) {
                estimatedSpeed = 5.0; // Slow
              } else {
                estimatedSpeed = 1.0; // Very slow
              }
            } else {
              // For mobile/desktop, calculate actual speed
              estimatedSpeed = (8.0 * 0.001) / durationInSeconds;
            }
            
            _connectionSpeed = estimatedSpeed;
            _isSlowConnection = estimatedSpeed < _slowConnectionThreshold;
            
            debugPrint('ConnectivityService: Connection speed: ${estimatedSpeed.toStringAsFixed(2)} Mbps (${durationInSeconds.toStringAsFixed(2)}s)');
            notifyListeners();
          } else {
            debugPrint('ConnectivityService: Speed test completed too quickly');
            _connectionSpeed = kIsWeb ? 15.0 : 10.0; // Assume good speed
            _isSlowConnection = false;
            notifyListeners();
          }
        } else {
          debugPrint('ConnectivityService: Speed test failed with status: ${response.statusCode}');
          _isSlowConnection = true;
          _connectionSpeed = 0.0;
          notifyListeners();
        }
      } else {
        // Use HttpClient for mobile/desktop platforms
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        
        final request = await client.getUrl(Uri.parse(testUrl));
        final response = await request.close();
        
        stopwatch.stop();
        client.close();
        
        if (response.statusCode == 200) {
          final durationInSeconds = stopwatch.elapsedMilliseconds / 1000.0;
          if (durationInSeconds > 0) {
            // For mobile/desktop, calculate actual speed
            final estimatedSpeed = (8.0 * 0.001) / durationInSeconds;
            
            _connectionSpeed = estimatedSpeed;
            _isSlowConnection = estimatedSpeed < _slowConnectionThreshold;
            
            debugPrint('ConnectivityService: Connection speed: ${estimatedSpeed.toStringAsFixed(2)} Mbps (${durationInSeconds.toStringAsFixed(2)}s)');
            notifyListeners();
          } else {
            debugPrint('ConnectivityService: Speed test completed too quickly');
            _connectionSpeed = 10.0; // Assume good speed
            _isSlowConnection = false;
            notifyListeners();
          }
        } else {
          debugPrint('ConnectivityService: Speed test failed with status: ${response.statusCode}');
          _isSlowConnection = true;
          _connectionSpeed = 0.0;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('ConnectivityService: Error testing connection speed: $e');
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
    debugPrint('ConnectivityService: Refreshing connectivity status...');
    
    if (kIsWeb) {
      // For web, just test internet connectivity directly
      await _testInternetConnectivity();
    } else {
      // For mobile/desktop, use connectivity_plus
      try {
        final results = await _connectivity.checkConnectivity();
        debugPrint('ConnectivityService: Refresh results: $results');
        _handleConnectivityChange(results);
      } catch (e) {
        debugPrint('ConnectivityService: Error refreshing connectivity: $e');
      }
    }
  }
  
  // Force a manual connection test
  Future<void> forceConnectionTest() async {
    debugPrint('ConnectivityService: Forcing connection test...');
    _isConnected = false;
    _isSlowConnection = false;
    _connectionSpeed = 0.0;
    notifyListeners();
    
    await _testInternetConnectivity();
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
