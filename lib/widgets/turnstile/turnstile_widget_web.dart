import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui;
import 'dart:async';

class TurnstileWidget extends StatefulWidget {
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
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final String _viewType;
  late final String _containerId;
  late final String _callbackName;
  String? _token;
  Timer? _retryTimer;
  bool _rendered = false;
  String? _widgetId;
  Timer? _pollTokenTimer;

  @override
  void initState() {
    super.initState();
    assert(kIsWeb, 'TurnstileWidget_web should only be used on web');

    final unique = DateTime.now().microsecondsSinceEpoch.toString();
    _viewType = 'turnstile-view-$unique';
    _containerId = 'turnstile-container-$unique';
    _callbackName = 'turnstileCallback_$unique';

    debugPrint('[Turnstile] initState - siteKey is ${widget.siteKey.isEmpty ? 'EMPTY' : 'SET'}');

    // Register global callback for Turnstile
    js_util.setProperty(web.window, _callbackName, js_util.allowInterop((dynamic token) {
      if (token is String) {
        setState(() {
          _token = token;
        });
        debugPrint('[Turnstile] onVerified token received (${token.substring(0, token.length > 8 ? 8 : token.length)}...)');
        widget.onVerified(token);
        // Collapse the widget to avoid overlay/pointer blocking
        final el = web.document.getElementById(_containerId) as web.HTMLElement?;
        final parent = el?.parentElement as web.HTMLElement?;
        if (el != null) {
          el.style.display = 'none';
          el.style.pointerEvents = 'none';
        }
        if (parent != null) {
          parent.style.height = '0px';
          parent.style.pointerEvents = 'none';
        }
      }
    }));

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      debugPrint('[Turnstile] registerViewFactory called for viewId=$viewId');
      final wrapper = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '70px'
        ..style.display = 'flex'
        ..style.justifyContent = 'center';

      final container = web.HTMLDivElement()
        ..id = _containerId
        ..classList.add('cf-turnstile')
        ..setAttribute('data-sitekey', widget.siteKey)
        ..setAttribute('data-callback', _callbackName)
        ..setAttribute('data-theme', widget.theme)
        ..style.marginTop = '8px'
        ..style.height = '70px';

      wrapper.append(container);
      // Attempt to render explicitly for dynamically added elements
      _attemptRender();
      return wrapper;
    });
  }

  void _attemptRender() {
    if (_rendered) return;
    // If site key is empty, skip attempting to render.
    if (widget.siteKey.isEmpty) {
      debugPrint('[Turnstile] _attemptRender aborted: site key is empty');
      return;
    }

    void tryRenderNow() {
      final bool hasTs = js_util.hasProperty(web.window, 'turnstile');
      final dynamic ts = hasTs ? js_util.getProperty(web.window, 'turnstile') : null;
      debugPrint('[Turnstile] tryRenderNow - turnstile present: ${ts != null}');
      if (ts != null) {
        // Prefer explicit render to ensure widget appears for dynamically inserted container
        try {
          final dynamic id = js_util.callMethod(ts, 'render', [
            '#$_containerId',
            js_util.jsify({
              'sitekey': widget.siteKey,
              'theme': widget.theme,
              'appearance': 'always',
              'callback': js_util.allowInterop((dynamic token) {
                if (token is String) {
                  setState(() => _token = token);
                  debugPrint('[Turnstile] callback token received (${token.substring(0, token.length > 8 ? 8 : token.length)}...)');
                  widget.onVerified(token);
                }
              }),
              'error-callback': js_util.allowInterop((dynamic code) {
                debugPrint('[Turnstile] error-callback code=${code.toString()}');
              }),
              'timeout-callback': js_util.allowInterop(() {
                debugPrint('[Turnstile] timeout-callback');
              }),
            })
          ]);
          _widgetId = id is String ? id : null;
          debugPrint('[Turnstile] render() invoked on #$_containerId');
          _rendered = true;
          _retryTimer?.cancel();
          _startPollingForTokenIfNeeded();
        } catch (_) {
          // ignore and let retry continue
          debugPrint('[Turnstile] render() threw, will retry');
        }
      }
    }

    // Try immediately
    debugPrint('[Turnstile] _attemptRender start');
    tryRenderNow();
    if (_rendered) return;

    // If not ready, poll a few times until the script loads
    int attempts = 0;
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      attempts += 1;
      tryRenderNow();
      if (_rendered || attempts > 50) {
        debugPrint('[Turnstile] stopping retries, rendered=$_rendered attempts=$attempts');
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _pollTokenTimer?.cancel();
    super.dispose();
  }

  void _startPollingForTokenIfNeeded() {
    if (_widgetId == null) return;
    _pollTokenTimer?.cancel();
    int attempts = 0;
    _pollTokenTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      attempts += 1;
      if (_token != null) {
        timer.cancel();
        return;
      }
      final bool hasTs = js_util.hasProperty(web.window, 'turnstile');
      if (!hasTs) return;
      final dynamic ts = js_util.getProperty(web.window, 'turnstile');
      try {
        final dynamic resp = js_util.callMethod(ts, 'getResponse', [_widgetId]);
        if (resp is String && resp.isNotEmpty) {
          setState(() => _token = resp);
          debugPrint('[Turnstile] polled token received (${resp.substring(0, resp.length > 8 ? 8 : resp.length)}...)');
          widget.onVerified(resp);
          timer.cancel();
        }
      } catch (_) {
        // ignore
      }
      if (attempts > 60) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 70,
          child: HtmlElementView(viewType: _viewType),
        ),
        if (_token == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Please complete the CAPTCHA to continue.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}


