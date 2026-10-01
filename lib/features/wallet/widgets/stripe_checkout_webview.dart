import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Result of a Stripe Checkout visit, from the backend's `?wallet=` redirect.
enum StripeCheckoutResult { success, failed, canceled }

/// Runs Stripe Checkout in a web view. The backend's success/cancel views
/// credit the wallet and redirect to `<frontend>/wallet?wallet=…`; we close on
/// that redirect, so the web frontend never needs to be reachable.
class StripeCheckoutScreen extends StatefulWidget {
  const StripeCheckoutScreen({super.key, required this.checkoutUrl});

  final String checkoutUrl;

  @override
  State<StripeCheckoutScreen> createState() => _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _done = false;

  static StripeCheckoutResult? _resultFor(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    switch (uri.queryParameters['wallet']) {
      case 'success':
        return StripeCheckoutResult.success;
      case 'failed':
        return StripeCheckoutResult.failed;
      case 'canceled':
        return StripeCheckoutResult.canceled;
    }
    // The cancel view has no work to do, so close as soon as it is requested.
    if (uri.path.endsWith('/stripe/cancel/')) return StripeCheckoutResult.canceled;
    return null;
  }

  void _finish(StripeCheckoutResult result) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.pop(context, result);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final result = _resultFor(request.url);
            if (result != null) {
              _finish(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          // Server redirects do not always raise a navigation request.
          onPageStarted: (url) {
            final result = _resultFor(url);
            if (result != null) return _finish(result);
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onUrlChange: (change) {
            final result = change.url == null ? null : _resultFor(change.url!);
            if (result != null) _finish(result);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card payment'),
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _finish(StripeCheckoutResult.canceled),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
