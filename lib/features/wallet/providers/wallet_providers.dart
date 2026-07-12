import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/auth_controller.dart';

class WalletData {
  const WalletData({
    required this.wallet,
    required this.plans,
    this.degraded = false,
    this.degradedMessage,
  });

  final WalletSummary wallet;
  final List<SubscriptionPlan> plans;
  final bool degraded;
  final String? degradedMessage;
}

const _fallbackPlans = [
  SubscriptionPlan(
    planId: 'duo_premium_7d',
    name: '7-Day Pass',
    description: 'Unlock Liked you for one week.',
    currency: 'NPR',
    amount: 149,
    durationDays: 7,
  ),
  SubscriptionPlan(
    planId: 'duo_premium_30d',
    name: '30-Day Pass',
    description: 'Unlock Liked you for one month.',
    currency: 'NPR',
    amount: 499,
    durationDays: 30,
    badge: 'Popular',
  ),
  SubscriptionPlan(
    planId: 'duo_premium_90d',
    name: '90-Day Pass',
    description: 'Best value — three months of Premium.',
    currency: 'NPR',
    amount: 999,
    durationDays: 90,
    badge: 'Best value',
  ),
];

WalletSummary _fallbackWalletSummary(int balance) {
  return WalletSummary(
    balance: balance,
    currency: 'NPR',
    topUpPresets: const [500, 1000, 2000, 5000],
    transactions: const [],
  );
}

final walletDataProvider = FutureProvider.autoDispose<WalletData>((ref) async {
  final walletRepo = ref.read(walletRepositoryProvider);
  final cachedBalance = ref.read(authControllerProvider).user?.profile.walletBalance ?? 0;

  WalletSummary wallet;
  var degraded = false;
  String? degradedMessage;

  try {
    wallet = await walletRepo.getWallet();
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      wallet = _fallbackWalletSummary(cachedBalance);
      degraded = true;
      degradedMessage =
          'Wallet API is not available on this server yet. Showing your cached balance. Pull to refresh after the backend redeploys.';
    } else {
      rethrow;
    }
  }

  var plans = await walletRepo.getPlans().catchError((_) => <SubscriptionPlan>[]);
  if (plans.isEmpty) {
    plans = _fallbackPlans;
  }

  return WalletData(
    wallet: wallet,
    plans: plans,
    degraded: degraded,
    degradedMessage: degradedMessage,
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
      final raw = e.raw;
      if (e.statusCode == 402 && raw is Map<String, dynamic>) {
        final required = raw['required'];
        final balance = raw['balance'];
        if (required != null && balance != null) {
          state = state.copyWith(
            clearPurchasing: true,
            notice:
                'Insufficient balance. You have NPR $balance but need NPR $required.',
          );
          return null;
        }
      }
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
