import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/duo_theme.dart';
import '../domain/wallet_domain.dart';

class WalletPremiumPlansSection extends StatelessWidget {
  const WalletPremiumPlansSection({
    super.key,
    required this.plans,
    required this.balance,
    required this.busy,
    required this.purchasingPlanId,
    required this.isPremium,
    required this.onPurchase,
  });

  final List<SubscriptionPlan> plans;
  final int balance;
  final bool busy;
  final String? purchasingPlanId;
  final bool isPremium;
  final ValueChanged<String> onPurchase;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREMIUM PASSES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DuoColors.primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < plans.length; i++)
                _PlanRow(
                  plan: plans[i],
                  balance: balance,
                  canAfford: balance >= plans[i].amount,
                  busy: busy,
                  loading: purchasingPlanId == plans[i].planId,
                  onPurchase: () {
                    HapticFeedback.mediumImpact();
                    onPurchase(plans[i].planId);
                  },
                  showDivider: i < plans.length - 1,
                ).animate(delay: (50 * i).ms).fadeIn().slideX(begin: 0.03, end: 0),
            ],
          ),
        ),
        if (!isPremium) ...[
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: 'Unlocks Liked you and Visited you on ',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.discover),
                    child: const Text(
                      'Discover',
                      style: TextStyle(
                        color: DuoColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.balance,
    required this.canAfford,
    required this.busy,
    required this.loading,
    required this.onPurchase,
    required this.showDivider,
  });

  final SubscriptionPlan plan;
  final int balance;
  final bool canAfford;
  final bool busy;
  final bool loading;
  final VoidCallback onPurchase;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (plan.badge != null && plan.badge!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: DuoColors.tertiary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              plan.badge!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: DuoColors.tertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.durationDays} days · ${formatNpr(plan.amount)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!canAfford)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Top up ${formatNpr(plan.amount - balance)} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: busy || !canAfford || loading ? null : onPurchase,
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buy'),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}
