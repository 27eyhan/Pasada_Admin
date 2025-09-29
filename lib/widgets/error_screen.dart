import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class ErrorScreen extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const ErrorScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  factory ErrorScreen.badRequest({VoidCallback? onRetry}) {
    return ErrorScreen(
      icon: Icons.report_gmailerrorred,
      iconColor: Palette.lightWarning,
      title: 'Bad Request',
      description: 'Your request could not be understood. Please check and try again.',
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Go Back',
      onSecondaryAction: null,
    );
  }

  factory ErrorScreen.authRequired({VoidCallback? onLogin}) {
    return ErrorScreen(
      icon: Icons.lock_outline,
      iconColor: Palette.greenColor,
      title: 'Authentication Required',
      description: 'Please sign in to continue.',
      primaryActionLabel: 'Sign In',
      onPrimaryAction: onLogin,
      secondaryActionLabel: 'Back',
      onSecondaryAction: null,
    );
  }

  factory ErrorScreen.forbidden({VoidCallback? onBack}) {
    return ErrorScreen(
      icon: Icons.block,
      iconColor: Colors.redAccent,
      title: 'Access Denied',
      description: 'You do not have permission to view this resource.',
      primaryActionLabel: 'Back',
      onPrimaryAction: onBack,
    );
  }

  factory ErrorScreen.badGateway({VoidCallback? onRetry}) {
    return ErrorScreen(
      icon: Icons.cloud_off,
      iconColor: Palette.lightWarning,
      title: 'Bad Gateway',
      description: 'Upstream service encountered a problem. Please try again shortly.',
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
      secondaryActionLabel: 'Back',
      onSecondaryAction: null,
    );
  }

  factory ErrorScreen.serviceUnavailable({VoidCallback? onRetry}) {
    return ErrorScreen(
      icon: Icons.settings_backup_restore,
      iconColor: Palette.lightWarning,
      title: 'Service Unavailable',
      description: 'The service is temporarily unavailable. Please try again later.',
      primaryActionLabel: 'Retry',
      onPrimaryAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Size size = MediaQuery.of(context).size;
    final bool isNarrow = size.width < 560;

    return Scaffold(
      backgroundColor: isDark ? Palette.darkSurface : Palette.lightSurface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 20 : 28,
                vertical: isNarrow ? 20 : 28,
              ),
              decoration: BoxDecoration(
                color: isDark ? Palette.darkCard : Palette.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Palette.darkBorder : Palette.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.06),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Palette.darkSurface : Palette.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                    ),
                    child: Icon(icon, size: 34, color: iconColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isNarrow ? 20 : 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PrimaryButton(label: primaryActionLabel, onPressed: onPrimaryAction ?? () => Navigator.of(context).pop()),
                      if (secondaryActionLabel != null) ...[
                        const SizedBox(width: 10),
                        _SecondaryButton(label: secondaryActionLabel!, onPressed: onSecondaryAction ?? () => Navigator.of(context).pop()),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        foregroundColor: Colors.white,
        backgroundColor: Palette.greenColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _SecondaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: isDark ? Palette.darkText : Palette.lightText,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}


