import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/wallet_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/duo_theme.dart';
import '../../widgets/duo_ui.dart';
import '../auth/auth_controller.dart';
import 'domain/wallet_domain.dart';
import 'providers/wallet_providers.dart';
import 'widgets/esewa_payment_webview.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/wallet_premium_plans_section.dart';
import 'widgets/wallet_skeleton.dart';
import 'widgets/wallet_topup_section.dart';
import 'widgets/wallet_transaction_list.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleQueryReturn());
  }

  void _handleQueryReturn() {
    final walletResult = GoRouterState.of(context).uri.queryParameters['wallet'];
    if (walletResult != null) {
      ref.read(walletUiProvider.notifier).handleWalletReturn(walletResult);
      context.replace('/wallet');
    }
  }

  Future<void> _startTopUp(int amount) async {
    final ui = ref.read(walletUiProvider.notifier);
    EsewaPaymentForm? form;
    try {
      form = await ui.initiateTopUp(amount);
      if (!mounted) return;
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EsewaPaymentScreen(form: form!)),
      );
      ui.clearToppingUp();
      if (!mounted) return;

      var toppedUp = success == true;
      if (success == null && form.transactionUuid.isNotEmpty) {
        try {
          final verified = await ref
              .read(walletRepositoryProvider)
              .verifyPayment(form.transactionUuid);
          toppedUp = verified['status'] == 'COMPLETE';
        } catch (_) {}
      }

      if (toppedUp) {
        ref.read(walletUiProvider.notifier).setNotice('Wallet topped up successfully.');
        await ref.read(walletUiProvider.notifier).refreshAll();
      } else if (success == false) {
        ref.read(walletUiProvider.notifier).setNotice('Top-up was not completed.');
      } else {
        ref.read(walletUiProvider.notifier).setNotice(
              'Payment submitted. Pull to refresh if your balance has not updated yet.',
            );
        await ref.read(walletUiProvider.notifier).refreshAll();
      }
    } on ApiException catch (e) {
      ui.clearToppingUp();
      if (mounted) {
        ref.read(walletUiProvider.notifier).setNotice(e.message);
      }
    } catch (_) {
      ui.clearToppingUp();
      if (mounted) {
        ref.read(walletUiProvider.notifier).setNotice('Could not start eSewa top-up.');
      }
    }
  }

  Future<void> _purchase(String planId) async {
    try {
      await ref.read(walletUiProvider.notifier).purchasePlan(planId);
    } on ApiException catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(walletDataProvider);
    final ui = ref.watch(walletUiProvider);
    final user = ref.watch(authControllerProvider).user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: DuoAmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    const BackButton(),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'DUO WALLET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: DuoColors.primary,
                            ),
                          ),
                          Text(
                            'Wallet',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(walletUiProvider.notifier).refreshAll(),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Top up with eSewa and use your balance for Duo Premium passes.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
                ),
              ),
              if (ui.notice != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Material(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(child: Text(ui.notice!)),
                          IconButton(
                            onPressed: () => ref.read(walletUiProvider.notifier).setNotice(null),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: data.when(
                  loading: () => const WalletSkeleton(),
                  error: (e, _) => _WalletError(
                    message: e is ApiException ? e.message : 'Could not load wallet.',
                    fallbackBalance: user?.profile.walletBalance ?? 0,
                    onRetry: () => ref.invalidate(walletDataProvider),
                  ),
                  data: (walletData) {
                    final wallet = walletData.wallet;
                    final balance = wallet.balance != 0
                        ? wallet.balance
                        : (user?.profile.walletBalance ?? wallet.balance);
                    final presets = wallet.topUpPresets.isNotEmpty
                        ? wallet.topUpPresets
                        : const [500, 1000, 2000, 5000];

                    return RefreshIndicator(
                      onRefresh: () => ref.read(walletUiProvider.notifier).refreshAll(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          WalletBalanceCard(
                            balance: balance,
                            hidden: ui.balanceHidden,
                            onToggleVisibility: () =>
                                ref.read(walletUiProvider.notifier).toggleBalanceVisibility(),
                            isPremium: user?.profile.isPremium ?? false,
                            premiumExpiry: premiumExpiryLabel(
                              user?.profile.subscriptionExpiresAt,
                            ),
                          ),
                          const SizedBox(height: 22),
                          WalletTopUpSection(
                            presets: presets,
                            busy: ui.busy,
                            toppingUp: ui.toppingUp,
                            onTopUp: _startTopUp,
                          ),
                          const SizedBox(height: 22),
                          WalletPremiumPlansSection(
                            plans: walletData.plans,
                            balance: balance,
                            busy: ui.busy,
                            purchasingPlanId: ui.purchasingPlanId,
                            isPremium: user?.profile.isPremium ?? false,
                            onPurchase: _purchase,
                          ),
                          const SizedBox(height: 22),
                          WalletTransactionList(
                            transactions: wallet.transactions,
                            query: ui.transactionQuery,
                            onQueryChanged:
                                ref.read(walletUiProvider.notifier).setTransactionQuery,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({
    required this.message,
    required this.fallbackBalance,
    required this.onRetry,
  });

  final String message;
  final int fallbackBalance;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: DuoColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (fallbackBalance > 0) ...[
              const SizedBox(height: 8),
              Text('Cached balance: ${formatNpr(fallbackBalance)}'),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
