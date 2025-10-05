import 'package:flutter/material.dart';
import 'package:pasada_admin_application/services/notification_transfer_service.dart';

class NotificationTransferWidget extends StatefulWidget {
  const NotificationTransferWidget({super.key});

  @override
  State<NotificationTransferWidget> createState() => _NotificationTransferWidgetState();
}

class _NotificationTransferWidgetState extends State<NotificationTransferWidget> {
  bool _isLoading = false;
  Map<String, dynamic> _statistics = {};
  String _lastTransferResult = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await NotificationTransferService.getQueueStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      _showError('Failed to load statistics: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _transferNotifications() async {
    setState(() => _isLoading = true);
    try {
      final result = await NotificationTransferService.manualTransferWithProgress();
      setState(() {
        _lastTransferResult = 'Transferred ${result['transferred']}/${result['total']} notifications';
        if (result['errors'] > 0) {
          _lastTransferResult += ' (${result['errors']} errors)';
        }
      });
      await _loadStatistics(); // Refresh statistics
    } catch (e) {
      _showError('Transfer failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupOldNotifications() async {
    setState(() => _isLoading = true);
    try {
      final cleanedCount = await NotificationTransferService.cleanupOldNotifications();
      setState(() {
        _lastTransferResult = 'Cleaned up $cleanedCount old notifications';
      });
      await _loadStatistics(); // Refresh statistics
    } catch (e) {
      _showError('Cleanup failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Notification Transfer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading ? null : _loadStatistics,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Statistics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Statistics
            if (_statistics.isNotEmpty) ...[
              _buildStatCard(
                'Queue Total',
                '${_statistics['queue_total'] ?? 0}',
                Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildStatCard(
                'History Total',
                '${_statistics['history_total'] ?? 0}',
                Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            // Last transfer result
            if (_lastTransferResult.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastTransferResult,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _transferNotifications,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Transfer to History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cleanupOldNotifications,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Cleanup Old'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
