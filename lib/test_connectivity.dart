import 'package:flutter/material.dart';
import 'package:pasada_admin_application/services/connectivity_service.dart';

class TestConnectivityPage extends StatefulWidget {
  const TestConnectivityPage({super.key});

  @override
  State<TestConnectivityPage> createState() => _TestConnectivityPageState();
}

class _TestConnectivityPageState extends State<TestConnectivityPage> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connectivity Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connectivity Status:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connected: ${_connectivityService.isConnected}'),
                    Text('Slow Connection: ${_connectivityService.isSlowConnection}'),
                    Text('Connection Speed: ${_connectivityService.connectionSpeed.toStringAsFixed(2)} Mbps'),
                    Text('Description: ${_connectivityService.getConnectionQualityDescription()}'),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                debugPrint('Manual refresh triggered');
                await _connectivityService.refreshConnectivity();
                await _connectivityService.performSpeedTest();
                setState(() {});
              },
              child: const Text('Refresh Connection'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _connectivityService.initialize();
                setState(() {});
              },
              child: const Text('Reinitialize Service'),
            ),
          ],
        ),
      ),
    );
  }
}
