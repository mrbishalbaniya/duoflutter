import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/duo_gradients.dart';
import '../../../core/theme/duo_theme.dart';
import '../domain/wallet_domain.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.hidden,
    required this.onToggleVisibility,
    this.premiumExpiry,
    this.isPremium = false,
  });

  final int balance;
  final bool hidden;
  final VoidCallback onToggleVisibility;
  final String? premiumExpiry;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DuoColors.primary.withValues(alpha: 0.18),
            scheme.surfaceContainerHigh,
          ],
        ),
        border: Border.all(color: DuoColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: DuoColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your coins',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: hidden
                ? Row(
                    key: const ValueKey(true),
                    children: [
                      Icon(Icons.toll_rounded, color: DuoColors.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '••••••',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey(false),
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Icon(Icons.toll_rounded, color: DuoColors.primary, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        formatCoinAmount(balance),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
          ),
          if (isPremium && premiumExpiry != null && premiumExpiry!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: DuoGradients.brandBr,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Premium active until $premiumExpiry',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.04, end: 0);
  }
}
