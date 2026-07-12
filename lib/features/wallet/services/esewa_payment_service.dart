import '../../../core/models/wallet_models.dart';

class EsewaPaymentService {
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

    final success = form.fields['success_url'];
    final failure = form.fields['failure_url'];
    if (success != null && success.isNotEmpty && url.startsWith(success)) {
      return true;
    }
    if (failure != null && failure.isNotEmpty && url.startsWith(failure)) {
      return false;
    }

    if (uri.path.contains('/esewa/success')) return true;
    if (uri.path.contains('/esewa/failure') || uri.path.contains('/esewa/fail')) {
      return false;
    }

    if (uri.path.contains('success') || uri.queryParameters.containsKey('success')) {
      return true;
    }
    if (uri.path.contains('fail') || uri.queryParameters.containsKey('failure')) {
      return false;
    }

    return null;
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
