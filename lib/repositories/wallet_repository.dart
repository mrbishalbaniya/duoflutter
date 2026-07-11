import '../core/models/wallet_models.dart';
import '../core/network/dio_client.dart';

class WalletRepository {
  WalletRepository(this._client);

  final DioClient _client;

  Future<WalletSummary> getWallet() async {
    final response = await _client.get<Map<String, dynamic>>('/wallet/');
    return WalletSummary.fromJson(response.data!);
  }

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _client.get<List<dynamic>>('/subscriptions/plan/');
    return (response.data ?? [])
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EsewaPaymentForm> initiateTopUp(int amount) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/wallet/topup/initiate/',
      data: {'amount': amount},
    );
    return EsewaPaymentForm.fromJson(response.data!);
  }

  Future<Map<String, dynamic>> purchasePlan(String planId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/wallet/purchase/',
      data: {'plan_id': planId},
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _client.get<Map<String, dynamic>>('/subscriptions/status/');
    return response.data ?? {};
  }
}
