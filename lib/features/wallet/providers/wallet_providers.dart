import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/auth_controller.dart';

class WalletData {
  const WalletData({
    required this.wallet,
    required this.plans,
  });

  final WalletSummary wallet;
  final List<SubscriptionPlan> plans;
}

final walletDataProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final walletRepo = ref.read(walletRepositoryProvider);
  final results = await Future.wait([
    walletRepo.getWallet(),
    walletRepo.getPlans().catchError((_) => <SubscriptionPlan>[]),
  ]);
  return WalletData(
    wallet: results[0] as WalletSummary,
    plans: results[1] as List<SubscriptionPlan>,
  );
});

class WalletUiState {
  const WalletUiState({
    this.toppingUp = false,
    this.purchasingPlanId,
    this.notice,
    this.balanceHidden = false,
    this.transactionQuery = '',
  });

  final bool toppingUp;
  final String? purchasingPlanId;
  final String? notice;
  final bool balanceHidden;
  final String transactionQuery;

  bool get busy => toppingUp || purchasingPlanId != null;

  WalletUiState copyWith({
    bool? toppingUp,
    String? purchasingPlanId,
    bool clearPurchasing = false,
    String? notice,
    bool clearNotice = false,
    bool? balanceHidden,
    String? transactionQuery,
  }) {
    return WalletUiState(
      toppingUp: toppingUp ?? this.toppingUp,
      purchasingPlanId:
          clearPurchasing ? null : (purchasingPlanId ?? this.purchasingPlanId),
      notice: clearNotice ? null : (notice ?? this.notice),
      balanceHidden: balanceHidden ?? this.balanceHidden,
      transactionQuery: transactionQuery ?? this.transactionQuery,
    );
  }
}

class WalletUiController extends StateNotifier<WalletUiState> {
  WalletUiController(this._ref) : super(const WalletUiState());

  final Ref _ref;

  void setNotice(String? message) {
    state = state.copyWith(notice: message, clearNotice: message == null);
  }

  void handleWalletReturn(String? result) {
    if (result == 'success') {
      setNotice('Wallet topped up successfully.');
      refreshAll();
    } else if (result == 'failed') {
      setNotice('Top-up was not completed.');
    }
  }

  void toggleBalanceVisibility() {
    state = state.copyWith(balanceHidden: !state.balanceHidden);
  }

  void setTransactionQuery(String query) {
    state = state.copyWith(transactionQuery: query);
  }

  Future<void> refreshAll() async {
    _ref.invalidate(walletDataProvider);
    await _ref.read(authControllerProvider.notifier).refreshUser();
  }

  Future<EsewaPaymentForm> initiateTopUp(int amount) async {
    state = state.copyWith(toppingUp: true, clearNotice: true);
    try {
      return await _ref.read(walletRepositoryProvider).initiateTopUp(amount);
    } on ApiException catch (e) {
      state = state.copyWith(toppingUp: false, notice: e.message);
      rethrow;
    } catch (_) {
      state = state.copyWith(
        toppingUp: false,
        notice: 'Could not start eSewa top-up.',
      );
      rethrow;
    }
  }

  void clearToppingUp() {
    state = state.copyWith(toppingUp: false);
  }

  Future<WalletPurchaseResult?> purchasePlan(String planId) async {
    state = state.copyWith(purchasingPlanId: planId, clearNotice: true);
    try {
      final result = await _ref.read(walletRepositoryProvider).purchasePlan(planId);
      state = state.copyWith(
        clearPurchasing: true,
        notice: '${result.plan.name} activated.',
      );
      await refreshAll();
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(clearPurchasing: true, notice: e.message);
      rethrow;
    } catch (_) {
      state = state.copyWith(
        clearPurchasing: true,
        notice: 'Could not purchase pass.',
      );
      rethrow;
    }
  }
}

final walletUiProvider =
    StateNotifierProvider.autoDispose<WalletUiController, WalletUiState>((ref) {
  return WalletUiController(ref);
});
