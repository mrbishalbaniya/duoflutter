import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/duo_theme.dart';
import '../../auth/auth_controller.dart';
import '../../wallet/domain/wallet_domain.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../../wallet/widgets/esewa_logo.dart';
import '../../wallet/widgets/esewa_payment_webview.dart';
import '../domain/discover_models.dart';

class PremiumUpgradeSheet extends ConsumerWidget {
  const PremiumUpgradeSheet({
    super.key,
    required this.variant,
    required this.count,
  });

  final PremiumSheetVariant variant;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletData = ref.watch(walletDataProvider);
    final ui = ref.watch(walletUiProvider);
    final title = variant == PremiumSheetVariant.likes
        ? 'See who liked you'
        : 'See who visited you';
    final subtitle = count > 0
        ? '$count ${variant == PremiumSheetVariant.likes ? 'likes' : 'visits'} waiting'
        : 'Unlock with Duo Premium';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DuoColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: DuoColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            walletData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(
                'Could not load plans.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              data: (data) {
                final wallet = data.wallet;
                final plans = data.plans;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Balance: ${formatNpr(wallet.balance)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    ...plans.map(
                      (plan) => _PlanTile(
                        plan: plan,
                        wallet: wallet,
                        loading: ui.purchasingPlanId == plan.planId,
                        busy: ui.busy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Top up via eSewa',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: wallet.topUpPresets
                          .map(
                            (amount) => OutlinedButton.icon(
                              onPressed: ui.busy
                                  ? null
                                  : () => _topUp(context, ref, amount),
                              icon: const EsewaLogo(size: 12),
                              label: Text(formatNpr(amount)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _topUp(BuildContext context, WidgetRef ref, int amount) async {
    EsewaPaymentForm? form;
    try {
      form = await ref.read(walletUiProvider.notifier).initiateTopUp(amount);
      if (!context.mounted) return;
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EsewaPaymentScreen(form: form!)),
      );
      ref.read(walletUiProvider.notifier).clearToppingUp();
      if (!context.mounted) return;

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
        await ref.read(walletUiProvider.notifier).refreshAll();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet topped up successfully.')),
        );
      } else if (success == false) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Top-up was not completed.')),
          );
        }
      } else {
        await ref.read(walletUiProvider.notifier).refreshAll();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment submitted. Pull to refresh if your balance has not updated yet.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      ref.read(walletUiProvider.notifier).clearToppingUp();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      ref.read(walletUiProvider.notifier).clearToppingUp();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start eSewa top-up.')),
        );
      }
    }
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({
    required this.plan,
    required this.wallet,
    required this.loading,
    required this.busy,
  });

  final SubscriptionPlan plan;
  final WalletSummary wallet;
  final bool loading;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAfford = wallet.balance >= plan.amount;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(plan.name),
        subtitle: Text('${plan.durationDays} days · ${formatNpr(plan.amount)}'),
        trailing: FilledButton(
          onPressed: !canAfford || busy || loading
              ? null
              : () async {
                  HapticFeedback.mediumImpact();
                  try {
                    await ref.read(walletUiProvider.notifier).purchasePlan(plan.planId);
                    await ref.read(authControllerProvider.notifier).refreshUser();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Premium activated!')),
                      );
                    }
                  } on ApiException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  }
                },
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Buy'),
        ),
      ),
    );
  }
}

void showPremiumUpgradeSheet(
  BuildContext context, {
  required PremiumSheetVariant variant,
  required int count,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PremiumUpgradeSheet(variant: variant, count: count),
  );
}
