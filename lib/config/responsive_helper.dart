import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1400;
  }

  static double getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return MediaQuery.of(context).size.width * 0.05;
  }

  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static int getGridCrossAxisCount(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeDesktop(context)) return largeDesktop;
    return desktop;
  }

  static double getResponsiveWidth(BuildContext context, {
    double? minWidth,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth;
    }
    
    final effectiveMinWidth = minWidth ?? 900.0;
    return screenWidth < effectiveMinWidth ? effectiveMinWidth : screenWidth;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);
    }
    return const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0);
  }

  static double getResponsiveIconSize(BuildContext context, {
    double mobile = 18.0,
    double tablet = 20.0,
    double desktop = 24.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static double getResponsiveAvatarRadius(BuildContext context, {
    double mobile = 16.0,
    double tablet = 18.0,
    double desktop = 20.0,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }
}
