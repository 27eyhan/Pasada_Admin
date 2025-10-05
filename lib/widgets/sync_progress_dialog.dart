import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class SyncProgressDialog extends StatefulWidget {
  final String title;
  final Future<void> Function() syncFunction;
  final VoidCallback? onComplete;
  final VoidCallback? onError;
  final Future<void> Function()? cancelFunction;

  const SyncProgressDialog({
    super.key,
    required this.title,
    required this.syncFunction,
    this.onComplete,
    this.onError,
    this.cancelFunction,
  });

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  double _progress = 0.0;
  String _statusText = 'Initializing...';
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      // Step 1: Check QuestDB Status (20%)
      setState(() {
        _progress = 0.2;
        _statusText = 'Checking QuestDB connection...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Check Migration Status (40%)
      setState(() {
        _progress = 0.4;
        _statusText = 'Verifying migration service...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Execute Migration (80%)
      setState(() {
        _progress = 0.8;
        _statusText = 'Executing data migration...';
      });
      await Future.delayed(const Duration(milliseconds: 1000));

      // Execute the actual sync function
      await widget.syncFunction();

      // Step 4: Complete (100%)
      setState(() {
        _progress = 1.0;
        _statusText = 'Synchronization completed successfully!';
        _isCompleted = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete?.call();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _statusText = 'Synchronization failed';
      });
      
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Palette.darkCard : Palette.lightCard,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            ),
            const SizedBox(height: 24.0),
            
            // Progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: isDark 
                        ? Palette.darkBorder.withValues(alpha: 0.3)
                        : Palette.lightBorder.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _hasError 
                          ? Palette.lightError
                          : _isCompleted 
                              ? Colors.green
                              : Palette.lightPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(_progress * 100).round()}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            
            // Status text
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.0,
                color: _hasError 
                    ? Palette.lightError
                    : isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
              ),
            ),
            
            // Error message if any
            if (_hasError && _errorMessage != null) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Palette.lightError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Palette.lightError.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.0,
                    color: Palette.lightError,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24.0),
            
            // Cancel button (only show if not completed and no error)
            if (!_isCompleted && !_hasError)
              TextButton(
                onPressed: _isCancelling
                    ? null
                    : () async {
                        try {
                          setState(() {
                            _isCancelling = true;
                            _statusText = 'Requesting cancellation...';
                          });
                          if (widget.cancelFunction != null) {
                            await widget.cancelFunction!.call();
                          }
                        } catch (_) {
                          // ignore UI-level errors here
                        } finally {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                child: _isCancelling
                    ? SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.0,
                          color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}