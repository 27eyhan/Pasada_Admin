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
        
        // For mobile screens, show icon-only version
        if (isMobile) {
          return _buildIconOnlyNotice(context, connectivityService);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 16, 
            vertical: isTablet ? 6 : 8
          ),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 16, 
                vertical: isTablet ? 10 : 12
              ),
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
                    size: isTablet ? 18 : 20,
                  ),
                  SizedBox(width: isTablet ? 10 : 12),
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
                            fontSize: isTablet ? 13 : 14,
                            color: connectivityService.isVerySlowConnection
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          connectivityService.getConnectionQualityDescription(),
                          style: TextStyle(
                            fontSize: isTablet ? 11 : 12,
                            color: connectivityService.isVerySlowConnection
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRefreshButton(connectivityService, isTablet),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconOnlyNotice(BuildContext context, ConnectivityService connectivityService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connectivityService.isVerySlowConnection
                    ? Icons.warning_rounded
                    : Icons.speed_rounded,
                color: connectivityService.isVerySlowConnection
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
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
      onTap: () => connectivityService.performSpeedTest(),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 4 : 6),
        decoration: BoxDecoration(
          color: connectivityService.isVerySlowConnection
              ? Colors.red.shade200
              : Colors.orange.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.refresh_rounded,
          color: connectivityService.isVerySlowConnection
              ? Colors.red.shade700
              : Colors.orange.shade700,
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
