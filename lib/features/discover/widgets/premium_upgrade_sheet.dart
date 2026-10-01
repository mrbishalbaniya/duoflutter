import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/duo_coin.dart';
import '../../auth/auth_controller.dart';
import '../../wallet/domain/wallet_domain.dart';
import '../../wallet/providers/wallet_providers.dart';
import '../domain/discover_models.dart';

class PremiumUpgradeSheet extends ConsumerStatefulWidget {
  const PremiumUpgradeSheet({
    super.key,
    required this.variant,
    required this.count,
    this.onPurchased,
  });

  final PremiumSheetVariant variant;
  final int count;

  /// Runs after a plan is bought (e.g. perform the rewind that was blocked).
  final VoidCallback? onPurchased;

  @override
  ConsumerState<PremiumUpgradeSheet> createState() => _PremiumUpgradeSheetState();
}

/// Port of DuoFrontend `components/ui/pricing-interaction.tsx` (used by the
/// Who Liked You / Visited You / Rewind / Unlimited Likes upgrade sheets).
class _PremiumUpgradeSheetState extends ConsumerState<PremiumUpgradeSheet> {
  String? _selectedPlanId;

  PremiumSheetVariant get variant => widget.variant;
  int get count => widget.count;
  VoidCallback? get onPurchased => widget.onPurchased;

  String get _headline => switch (variant) {
        PremiumSheetVariant.unlimitedLikes => 'Keep liking without limits',
        PremiumSheetVariant.rewind => 'Rewind your last swipe',
        PremiumSheetVariant.visitors => 'See who viewed you',
        PremiumSheetVariant.likes => 'See who liked you',
      };

  String get _subtitle {
    final people = count == 1 ? 'person has' : 'people have';
    return switch (variant) {
      PremiumSheetVariant.unlimitedLikes =>
        "You've used your free Likes for now. Go unlimited so you never miss someone you like.",
      PremiumSheetVariant.rewind => 'Swiped too fast? Bring back people you passed on or liked by mistake.',
      PremiumSheetVariant.visitors when count > 0 =>
        '$count $people viewed your profile. Unlock blurred profiles and connect.',
      PremiumSheetVariant.likes when count > 0 =>
        '$count $people liked you. Unlock blurred profiles and match instantly.',
      PremiumSheetVariant.visitors => 'Upgrade to see who has been checking out your profile.',
      PremiumSheetVariant.likes => 'Upgrade to unlock blurred profiles when someone likes you.',
    };
  }

  List<String> get _perks => switch (variant) {
        PremiumSheetVariant.unlimitedLikes => const ['Like as many people as you want', 'No 12-hour Like limit'],
        PremiumSheetVariant.rewind => const ['Undo left and right swipes', 'Rewind as many times as you like'],
        PremiumSheetVariant.visitors => const [
            'Reveal names and photos on Visited you',
            'See who checked out your profile first',
          ],
        PremiumSheetVariant.likes => const [
            'Reveal names and photos on Liked you',
            'Match instantly with people who like you',
          ],
      };

  Future<void> _purchase(SubscriptionPlan plan) async {
    HapticFeedback.mediumImpact();
    try {
      await ref.read(walletUiProvider.notifier).purchasePlan(plan.planId);
      if (!mounted) return;
      await ref.read(authControllerProvider.notifier).refreshUser();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      onPurchased?.call();
      messenger.showSnackBar(
        SnackBar(content: Text(plan.featureLabel != null ? '${plan.featureLabel} unlocked!' : 'Premium activated!')),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final walletData = ref.watch(walletDataProvider);
    final plansAsync = ref.watch(featurePlansProvider(variant.feature));
    final ui = ref.watch(walletUiProvider);
    final balance = walletData.valueOrNull?.wallet.balance ??
        ref.watch(authControllerProvider).user?.profile.walletBalance ??
        0;
    final plans = plansAsync.valueOrNull ?? const <SubscriptionPlan>[];
    final popular = plans.indexWhere((p) => (p.badge ?? '').toLowerCase() == 'popular');
    final selected = plans.isEmpty
        ? null
        : plans.firstWhere(
            (p) => p.planId == _selectedPlanId,
            orElse: () => plans[popular >= 0 ? popular : 0],
          );
    final shortfall = selected == null ? 0 : (selected.amount - balance).clamp(0, 1 << 31);
    final canAfford = shortfall == 0;
    final purchasing = selected != null && ui.purchasingPlanId == selected.planId;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Duo Coins" pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DuoCoin(size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'DUO COINS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(_headline,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(_subtitle, style: TextStyle(fontSize: 14, height: 1.45, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            // Your coins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Text('Your coins', style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                  const Spacer(),
                  const DuoCoin(size: 18),
                  const SizedBox(width: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: balance.toDouble()),
                    duration: const Duration(milliseconds: 500),
                    builder: (_, v, __) => Text(
                      formatCoinAmount(v.round()),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final perk in [
              ..._perks,
              if (selected != null) '${selected.durationDays}-day access · ${formatCoinAmount(selected.amount)} coins',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(perk, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant))),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Plan picker card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.35)),
                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (plansAsync.isLoading && plans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (plans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No plans available right now.',
                          textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ),
                  for (final plan in plans) ...[
                    _PlanOption(
                      plan: plan,
                      active: plan.planId == selected?.planId,
                      onTap: ui.busy ? null : () => setState(() => _selectedPlanId = plan.planId),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (selected != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(shape: const StadiumBorder()),
                        onPressed: ui.busy || !canAfford ? null : () => _purchase(selected),
                        icon: purchasing
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.shopping_bag_outlined),
                        label: Text(
                          purchasing
                              ? 'Purchasing…'
                              : canAfford
                                  ? 'Buy pass · ${formatCoins(selected.amount)}'
                                  : 'Need ${formatCoinAmount(shortfall)} more coins',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (canAfford)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Purchases are deducted from your coin balance',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        ),
                      )
                    else ...[
                      Divider(height: 28, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      // Web: a single link to the wallet instead of top-up amounts.
                      Center(
                        child: TextButton(
                          onPressed: () {
                            final router = GoRouter.of(context);
                            Navigator.pop(context);
                            router.push(AppRoutes.wallet);
                          },
                          child: const Text(
                            "Don't have coins? Recharge",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({required this.plan, required this.active, required this.onTap});

  final SubscriptionPlan plan;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary.withValues(alpha: 0.08) : scheme.surface.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(plan.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          if ((plan.badge ?? '').isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan.badge!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${formatCoinAmount(plan.amount)} coins',
                              style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
                            ),
                            TextSpan(text: ' / ${plan.durationDays} days'),
                          ],
                        ),
                        style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Radio dot
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: active ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showPremiumUpgradeSheet(
  BuildContext context, {
  required PremiumSheetVariant variant,
  required int count,
  VoidCallback? onPurchased,
}) {
  showModalBottomSheet<void>(
    context: context,
    // Root navigator: otherwise the sheet opens inside the tab and the bottom
    // navigation bar is drawn on top of it.
    useRootNavigator: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PremiumUpgradeSheet(variant: variant, count: count, onPurchased: onPurchased),
  );
}
