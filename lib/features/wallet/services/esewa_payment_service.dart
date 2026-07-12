import 'dart:async';
import 'dart:io';

import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/wallet_models.dart';

enum EsewaPaymentOutcome { success, failure, cancelled }

class EsewaNativePaymentResult {
  const EsewaNativePaymentResult({
    required this.outcome,
    this.refId,
  });

  final EsewaPaymentOutcome outcome;
  final String? refId;
}

class EsewaPaymentService {
  bool get supportsNativeSdk =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Environment _environmentFor(String? value) {
    return value == 'live' ? Environment.live : Environment.test;
  }

  Future<EsewaNativePaymentResult> startNativePayment(EsewaPaymentForm form) async {
    final sdk = form.mobileSdk;
    if (!supportsNativeSdk || sdk == null) {
      throw UnsupportedError('Native eSewa SDK is only available on Android/iOS.');
    }

    final completer = Completer<EsewaNativePaymentResult>();

    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: _environmentFor(sdk.environment),
          clientId: sdk.clientId,
          secretId: sdk.secretId,
        ),
        esewaPayment: EsewaPayment(
          productId: sdk.productId,
          productName: sdk.productName,
          productPrice: sdk.productPrice,
          callbackUrl: sdk.callbackUrl,
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) {
          debugPrint('eSewa success => $data');
          if (!completer.isCompleted) {
            completer.complete(
              EsewaNativePaymentResult(
                outcome: EsewaPaymentOutcome.success,
                refId: data.refId,
              ),
            );
          }
        },
        onPaymentFailure: (data) {
          debugPrint('eSewa failure => $data');
          if (!completer.isCompleted) {
            completer.complete(
              const EsewaNativePaymentResult(outcome: EsewaPaymentOutcome.failure),
            );
          }
        },
        onPaymentCancellation: (data) {
          debugPrint('eSewa cancelled => $data');
          if (!completer.isCompleted) {
            completer.complete(
              const EsewaNativePaymentResult(outcome: EsewaPaymentOutcome.cancelled),
            );
          }
        },
      );
    } on Exception catch (e) {
      debugPrint('eSewa exception => $e');
      throw Exception('Could not open eSewa payment: $e');
    }

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => const EsewaNativePaymentResult(outcome: EsewaPaymentOutcome.cancelled),
    );
  }

  String buildAutoSubmitHtml({
    required String paymentUrl,
    required Map<String, String> fields,
  }) {
    final inputs = fields.entries
        .map(
          (e) =>
              '<input type="hidden" name="${_escapeHtml(e.key)}" value="${_escapeHtml(e.value)}">',
        )
        .join();

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Redirecting to eSewa…</title>
  <style>
    body { font-family: sans-serif; display:flex; align-items:center; justify-content:center; min-height:100vh; margin:0; background:#111; color:#fff; }
  </style>
</head>
<body>
  <p>Redirecting to eSewa…</p>
  <form id="esewa" method="POST" action="${_escapeHtml(paymentUrl)}">
    $inputs
  </form>
  <script>document.getElementById('esewa').submit();</script>
</body>
</html>
''';
  }

  bool? paymentResultFromUrl(String url, EsewaPaymentForm form) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final wallet = uri.queryParameters['wallet'];
    if (wallet == 'success') return true;
    if (wallet == 'failed' || wallet == 'failure') return false;

    final subscription = uri.queryParameters['subscription'];
    if (subscription == 'success') return true;
    if (subscription == 'failed' || subscription == 'failure') return false;

    final success = form.fields['success_url'];
    final failure = form.fields['failure_url'];
    if (success != null && success.isNotEmpty && _urlMatches(url, success)) {
      return true;
    }
    if (failure != null && failure.isNotEmpty && _urlMatches(url, failure)) {
      return false;
    }

    if (uri.path.contains('/esewa/success')) return true;
    if (uri.path.contains('/esewa/failure') || uri.path.contains('/esewa/fail')) {
      return false;
    }

    return null;
  }

  bool _urlMatches(String current, String target) {
    if (current.startsWith(target)) return true;
    final currentUri = Uri.tryParse(current);
    final targetUri = Uri.tryParse(target);
    if (currentUri == null || targetUri == null) return false;
    return currentUri.host == targetUri.host &&
        currentUri.path.startsWith(targetUri.path);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
