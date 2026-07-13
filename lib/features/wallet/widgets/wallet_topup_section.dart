import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_theme.dart';
import '../domain/wallet_domain.dart';
import 'esewa_logo.dart';

class WalletTopUpSection extends StatelessWidget {
  const WalletTopUpSection({
    super.key,
    required this.presets,
    required this.busy,
    required this.toppingUp,
    required this.onTopUp,
  });

  final List<int> presets;
  final bool busy;
  final bool toppingUp;
  final ValueChanged<int> onTopUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUY COINS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DuoColors.primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 360 ? 4 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final coins = presets[index];
                      return _CoinPackChip(
                        coins: coins,
                        disabled: busy,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onTopUp(coins);
                        },
                      ).animate(delay: (40 * index).ms).fadeIn().scale(
                            begin: const Offset(0.96, 0.96),
                            end: const Offset(1, 1),
                          );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                toppingUp
                    ? 'Redirecting to eSewa…'
                    : '1 NPR via eSewa = 1 Duo Coin · Secure payment with eSewa ePay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoinPackChip extends StatelessWidget {
  const _CoinPackChip({
    required this.coins,
    required this.disabled,
    required this.onTap,
  });

  final int coins;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DuoColors.esewaGreen.withValues(alpha: 0.25),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.toll_rounded, size: 16, color: DuoColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    formatCoinAmount(coins),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EsewaLogo(size: 12),
                  const SizedBox(width: 4),
                  Text(
                    formatNprPrice(coins),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
