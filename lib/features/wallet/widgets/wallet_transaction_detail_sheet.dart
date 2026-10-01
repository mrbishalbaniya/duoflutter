import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/duo_theme.dart';
import '../../../widgets/duo_ui.dart';
import '../domain/wallet_domain.dart';

/// Detail of one transaction (web `WalletTransactionDetailPage`). Shows the row's
/// data immediately and refreshes it from `GET /wallet/transactions/<id>/`.
Future<void> showWalletTransactionDetail(BuildContext context, WalletTransaction txn) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _TransactionDetailSheet(initial: txn),
  );
}

Color walletStatusColor(ColorScheme scheme, String status) => switch (status) {
      'pending' => const Color(0xFFF59E0B),
      'failed' => scheme.error,
      _ => DuoColors.accent,
    };

/// Small uppercase status pill used in lists and the detail sheet.
class WalletStatusBadge extends StatelessWidget {
  const WalletStatusBadge({super.key, required this.txn});

  final WalletTransaction txn;

  @override
  Widget build(BuildContext context) {
    final color = walletStatusColor(Theme.of(context).colorScheme, txn.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(
        txn.statusLabel.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: color),
      ),
    );
  }
}

class _TransactionDetailSheet extends ConsumerStatefulWidget {
  const _TransactionDetailSheet({required this.initial});

  final WalletTransaction initial;

  @override
  ConsumerState<_TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends ConsumerState<_TransactionDetailSheet> {
  late WalletTransaction _txn = widget.initial;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.initial.id;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fresh = await ref.read(walletRepositoryProvider).getTransaction(id);
      if (mounted) setState(() => _txn = fresh);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final txn = _txn;
    Widget row(String label, String value, {bool copy = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (copy && value.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.copy_rounded, size: 16, color: scheme.primary),
                  ),
                ),
            ],
          ),
        );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatTxnAmount(txn.amount),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: txn.isCredit ? DuoColors.esewaGreen : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(txn.displayTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            WalletStatusBadge(txn: txn),
            if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: scheme.error),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_error!, style: TextStyle(color: scheme.error, fontSize: 12))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            row('Status', txn.statusLabel),
            row('Payment method', txn.paymentMethodLabel),
            if (txn.totalAmount.isNotEmpty && txn.totalAmount != txn.amount)
              row('Total', formatTxnAmount(txn.totalAmount)),
            row('Balance after', formatTxnAmount(txn.balanceAfter).replaceFirst('+', '')),
            row('Date', formatTxnDate(txn.createdAt)),
            if (txn.id != null) row('Transaction ID', '#${txn.id}', copy: true),
            if (txn.referenceId.isNotEmpty) row('Reference', txn.referenceId, copy: true),
          ],
        ),
      ),
    );
  }
}
