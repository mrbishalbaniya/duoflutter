import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/wallet_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../auth/auth_controller.dart';

final walletDataProvider = FutureProvider.autoDispose<(WalletSummary, List<SubscriptionPlan>)>((ref) async {
  final walletRepo = ref.read(walletRepositoryProvider);
  final results = await Future.wait([
    walletRepo.getWallet(),
    walletRepo.getPlans(),
  ]);
  return (results[0] as WalletSummary, results[1] as List<SubscriptionPlan>);
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  Future<void> _topUp(BuildContext context, WidgetRef ref, int amount) async {
    try {
      final form = await ref.read(walletRepositoryProvider).initiateTopUp(amount);
      final uri = Uri.parse(form.paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open eSewa. Complete top-up on web for now.')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, String planId) async {
    try {
      await ref.read(walletRepositoryProvider).purchasePlan(planId);
      ref.invalidate(walletDataProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium pass purchased.')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(walletDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tuple) {
          final wallet = tuple.$1;
          final plans = tuple.$2;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NPR ${wallet.balance}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Top up via eSewa', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wallet.topUpPresets
                    .map(
                      (amount) => OutlinedButton(
                        onPressed: () => _topUp(context, ref, amount),
                        child: Text('NPR $amount'),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text('Premium passes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...plans.map(
                (plan) => Card(
                  child: ListTile(
                    title: Text(plan.name),
                    subtitle: Text('${plan.durationDays} days'),
                    trailing: FilledButton(
                      onPressed: wallet.balance >= plan.amount
                          ? () => _purchase(context, ref, plan.planId)
                          : null,
                      child: Text('NPR ${plan.amount}'),
                    ),
                  ),
                ),
              ),
              if (wallet.transactions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
                ...wallet.transactions.map(
                  (t) => ListTile(
                    title: Text(t.description.isNotEmpty ? t.description : t.type),
                    subtitle: Text(t.createdAt),
                    trailing: Text(t.amount),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
