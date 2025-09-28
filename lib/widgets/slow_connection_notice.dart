import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pasada_admin_application/services/connectivity_service.dart';
import 'package:pasada_admin_application/config/responsive_helper.dart';

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

        final isMobile = ResponsiveHelper.isMobile(context);
        final isTablet = ResponsiveHelper.isTablet(context);
        
        // For mobile screens, show floating icon-only version
        if (isMobile) {
          return _buildIconOnlyNotice(context, connectivityService);
        }

        return Positioned(
          top: 90,
          left: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 16, 
                  vertical: isTablet ? 10 : 12
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: connectivityService.isVerySlowConnection
                      ? Colors.red.shade900.withOpacity(0.9)
                      : Colors.orange.shade900.withOpacity(0.9),
                  border: Border.all(
                    color: connectivityService.isVerySlowConnection
                        ? Colors.red.shade600
                        : Colors.orange.shade600,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectivityService.isVerySlowConnection
                          ? Icons.warning_rounded
                          : Icons.speed_rounded,
                      color: Colors.white,
                      size: isTablet ? 18 : 20,
                    ),
                    SizedBox(width: isTablet ? 10 : 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          connectivityService.isVerySlowConnection
                              ? 'Very Slow Internet Connection'
                              : 'Slow Internet Connection',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isTablet ? 13 : 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connectivityService.getConnectionQualityDescription(),
                          style: TextStyle(
                            fontSize: isTablet ? 11 : 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: isTablet ? 8 : 12),
                    _buildRefreshButton(connectivityService, isTablet),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconOnlyNotice(BuildContext context, ConnectivityService connectivityService) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: connectivityService.isVerySlowConnection
                ? Colors.red.shade900.withOpacity(0.9)
                : Colors.orange.shade900.withOpacity(0.9),
            border: Border.all(
              color: connectivityService.isVerySlowConnection
                  ? Colors.red.shade600
                  : Colors.orange.shade600,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connectivityService.isVerySlowConnection
                    ? Icons.warning_rounded
                    : Icons.speed_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              _buildRefreshButton(connectivityService, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(ConnectivityService connectivityService, bool isSmall) {
    return GestureDetector(
      onTap: () async {
        // Perform both connectivity refresh and speed test
        await connectivityService.refreshConnectivity();
        await connectivityService.performSpeedTest();
      },
      child: Container(
        padding: EdgeInsets.all(isSmall ? 4 : 6),
        decoration: BoxDecoration(
          color: isSmall 
              ? Colors.white.withOpacity(0.2)
              : (connectivityService.isVerySlowConnection
                  ? Colors.red.shade200
                  : Colors.orange.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.refresh_rounded,
          color: isSmall 
              ? Colors.white
              : (connectivityService.isVerySlowConnection
                  ? Colors.red.shade700
                  : Colors.orange.shade700),
          size: isSmall ? 12 : 14,
        ),
      ),
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
