import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/theme/duo_theme.dart';
import '../domain/wallet_domain.dart';

class WalletTransactionList extends StatelessWidget {
  const WalletTransactionList({
    super.key,
    required this.transactions,
    required this.query,
    required this.onQueryChanged,
  });

  final List<WalletTransaction> transactions;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = filterTransactions(transactions, query);
    final grouped = groupTransactionsByDate(filtered);
    final scheme = Theme.of(context).colorScheme;

    if (transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search transactions',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No transactions match your search.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DuoColors.primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < entry.value.length; i++)
                    _TransactionTile(
                      txn: entry.value[i],
                      showDivider: i < entry.value.length - 1,
                    ).animate(delay: (30 * i).ms).fadeIn(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.txn,
    required this.showDivider,
  });

  final WalletTransaction txn;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (txn.type) {
      'top_up' => Icons.add_card_rounded,
      'purchase' => Icons.workspace_premium_outlined,
      'adjustment' => Icons.tune_rounded,
      _ => Icons.receipt_long_rounded,
    };

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: txn.isCredit
                ? DuoColors.esewaGreen.withValues(alpha: 0.15)
                : scheme.surfaceContainerHighest,
            child: Icon(
              icon,
              color: txn.isCredit ? DuoColors.esewaGreen : scheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Text(
            txn.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(formatTxnDate(txn.createdAt)),
          trailing: Text(
            formatTxnAmount(txn.amount),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: txn.isCredit ? DuoColors.esewaGreen : scheme.onSurface,
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            color: scheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
