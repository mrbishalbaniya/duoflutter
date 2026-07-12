import '../core/models/wallet_models.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';

class WalletRepository {
  WalletRepository(this._client);

  final DioClient _client;

  static const _primaryPrefix = '/wallet';
  static const _fallbackPrefix = '/subscriptions/wallet';

  Future<T> _withWalletFallback<T>(
    Future<T> Function(String prefix) action,
  ) async {
    try {
      return await action(_primaryPrefix);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return await action(_fallbackPrefix);
      }
      rethrow;
    }
  }

  Future<WalletSummary> getWallet() async {
    return _withWalletFallback((prefix) async {
      final response = await _client.get<Map<String, dynamic>>('$prefix/');
      return WalletSummary.fromJson(response.data!);
    });
  }

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _client.get<List<dynamic>>('/subscriptions/plan/');
    return (response.data ?? [])
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EsewaPaymentForm> initiateTopUp(int amount) async {
    return _withWalletFallback((prefix) async {
      final response = await _client.post<Map<String, dynamic>>(
        '$prefix/topup/initiate/',
        data: {'amount': amount},
      );
      return EsewaPaymentForm.fromJson(response.data!);
    });
  }

  Future<WalletPurchaseResult> purchasePlan(String planId) async {
    return _withWalletFallback((prefix) async {
      final response = await _client.post<Map<String, dynamic>>(
        '$prefix/purchase/',
        data: {'plan_id': planId},
      );
      return WalletPurchaseResult.fromJson(response.data!);
    });
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _client.get<Map<String, dynamic>>('/subscriptions/status/');
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> verifyPayment(
    String transactionUuid, {
    String? refId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/subscriptions/verify/',
      data: {
        'transaction_uuid': transactionUuid,
        if (refId != null && refId.isNotEmpty) 'ref_id': refId,
      },
    );
    return response.data ?? {};
  }
}
