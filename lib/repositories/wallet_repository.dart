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

  /// Full, cursor-paginated history (web `WalletTransactionsPage`).
  Future<WalletTransactionPage> getTransactions({
    int? before,
    int limit = 20,
    String paymentMethod = '',
    String? dateFrom,
    String? dateTo,
  }) async {
    return _withWalletFallback((prefix) async {
      final response = await _client.get<Map<String, dynamic>>(
        '$prefix/transactions/',
        queryParameters: {
          'limit': limit,
          if (before != null) 'before': before,
          if (paymentMethod.isNotEmpty) 'payment_method': paymentMethod,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        },
      );
      return WalletTransactionPage.fromJson(response.data ?? const {});
    });
  }

  Future<WalletTransaction> getTransaction(int id) async {
    return _withWalletFallback((prefix) async {
      final response = await _client.get<Map<String, dynamic>>('$prefix/transactions/$id/');
      return WalletTransaction.fromJson(response.data!);
    });
  }

  Future<GiftCardRedeemResult> redeemGiftCard(String code) async {
    return _withWalletFallback((prefix) async {
      final response = await _client.post<Map<String, dynamic>>(
        '$prefix/giftcard/redeem/',
        data: {'code': code.trim()},
      );
      return GiftCardRedeemResult.fromJson(response.data ?? const {});
    });
  }

  Future<List<SubscriptionPlan>> getPlans({
    String feature = SubscriptionFeature.whoLikedYou,
  }) async {
    final response = await _client.get<List<dynamic>>(
      '/subscriptions/plan/',
      queryParameters: {'feature': feature},
    );
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

  /// Start a Stripe Checkout session for a card top-up (web `initiateStripeTopUp`).
  Future<StripeCheckout> initiateStripeTopUp(int amount) async {
    return _withWalletFallback((prefix) async {
      final response = await _client.post<Map<String, dynamic>>(
        '$prefix/topup/stripe/',
        data: {'amount': amount},
      );
      return StripeCheckout.fromJson(response.data!);
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
