import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/connectivity_service.dart';

class SlowConnectionNotice extends StatelessWidget {
  const SlowConnectionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        // Don't show notice if connection is good or disconnected
        if (!connectivityService.isConnected || !connectivityService.isSlowConnection) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: connectivityService.isVerySlowConnection
                      ? [Colors.red.shade100, Colors.red.shade50]
                      : [Colors.orange.shade100, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: connectivityService.isVerySlowConnection
                      ? Colors.red.shade300
                      : Colors.orange.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    connectivityService.isVerySlowConnection
                        ? Icons.warning_rounded
                        : Icons.speed_rounded,
                    color: connectivityService.isVerySlowConnection
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          connectivityService.isVerySlowConnection
                              ? 'Very Slow Internet Connection'
                              : 'Slow Internet Connection',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: connectivityService.isVerySlowConnection
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connectivityService.getConnectionQualityDescription(),
                          style: TextStyle(
                            fontSize: 12,
                            color: connectivityService.isVerySlowConnection
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => connectivityService.performSpeedTest(),
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: connectivityService.isVerySlowConnection
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                      size: 18,
                    ),
                    tooltip: 'Test connection speed',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternative compact version for smaller screens
class CompactSlowConnectionNotice extends StatelessWidget {
  const CompactSlowConnectionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        if (!connectivityService.isConnected || !connectivityService.isSlowConnection) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: connectivityService.isVerySlowConnection
                ? Colors.red.shade50
                : Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(
                color: connectivityService.isVerySlowConnection
                    ? Colors.red.shade200
                    : Colors.orange.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connectivityService.isVerySlowConnection
                    ? Icons.warning_rounded
                    : Icons.speed_rounded,
                color: connectivityService.isVerySlowConnection
                    ? Colors.red.shade600
                    : Colors.orange.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connectivityService.isVerySlowConnection
                      ? 'Very slow connection detected'
                      : 'Slow connection detected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: connectivityService.isVerySlowConnection
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => connectivityService.performSpeedTest(),
                child: Icon(
                  Icons.refresh_rounded,
                  color: connectivityService.isVerySlowConnection
                      ? Colors.red.shade600
                      : Colors.orange.shade600,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
