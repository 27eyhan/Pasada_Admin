import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class TurnstileWidget extends StatelessWidget {
  final void Function(String token) onVerified;
  final String siteKey;
  final String theme;

  const TurnstileWidget({
    super.key,
    required this.onVerified,
    required this.siteKey,
    this.theme = 'auto',
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        'CAPTCHA is only required on the web login.',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Colors.grey[400]),
        textAlign: TextAlign.center,
      ),
    );
  }
}


