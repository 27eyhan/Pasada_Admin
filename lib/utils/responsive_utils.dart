import 'package:flutter/material.dart';

class ResponsiveUtils {
  /// Check if the current screen size is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  /// Check if the current screen size is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  /// Check if the current screen size is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Get responsive dialog constraints
  static BoxConstraints getDialogConstraints(BuildContext context) {
    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.95,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      );
    } else {
      return BoxConstraints(
        maxWidth: 800,
        maxHeight: 700,
      );
    }
  }

  /// Show responsive dialog or bottom sheet
  static Future<T?> showResponsiveDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    if (isMobile(context)) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => child,
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: getDialogConstraints(context),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: child,
              ),
            ),
          ),
        ),
      );
    }
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }
}
