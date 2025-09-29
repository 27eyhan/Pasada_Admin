import 'package:flutter/material.dart';
import 'package:pasada_admin_application/widgets/error_screen.dart';

class ErrorResult {
  final bool handledWithScreen;
  final String? message;
  const ErrorResult.screen() : handledWithScreen = true, message = null;
  const ErrorResult.message(this.message) : handledWithScreen = false;
}

class ErrorHandler {
  static ErrorResult handleStatus({
    required BuildContext context,
    required int statusCode,
    VoidCallback? onRetry,
    VoidCallback? onLogin,
  }) {
    switch (statusCode) {
      case 400:
        _push(context, ErrorScreen.badRequest(onRetry: onRetry));
        return const ErrorResult.screen();
      case 401:
        _push(context, ErrorScreen.authRequired(onLogin: onLogin));
        return const ErrorResult.screen();
      case 403:
        _push(context, ErrorScreen.forbidden(onBack: () => Navigator.of(context).maybePop()));
        return const ErrorResult.screen();
      case 404:
        return const ErrorResult.message('We could not find what you’re looking for. It may have been moved or no longer exists.');
      case 500:
        return const ErrorResult.message('Unknown error. Please try to refresh the website and try again.');
      case 502:
        _push(context, ErrorScreen.badGateway(onRetry: onRetry));
        return const ErrorResult.screen();
      case 503:
        _push(context, ErrorScreen.serviceUnavailable(onRetry: onRetry));
        return const ErrorResult.screen();
      default:
        return const ErrorResult.message('Something went wrong. Please try again.');
    }
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation.drive(tween), child: child),
          );
        },
      ),
    );
  }
}


