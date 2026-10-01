import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/wallet_models.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/duo_theme.dart';
import '../../widgets/duo_ui.dart';
import 'domain/wallet_domain.dart';
import 'widgets/wallet_transaction_detail_sheet.dart';

/// Full wallet history (web `WalletTransactionsPage`): cursor pagination with
/// infinite scroll, payment-method filter, pull-to-refresh and detail sheet.
class WalletTransactionsScreen extends ConsumerStatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  ConsumerState<WalletTransactionsScreen> createState() => _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends ConsumerState<WalletTransactionsScreen> {
  static const _methods = <(String, String)>[
    ('', 'All methods'),
    ('esewa', 'eSewa'),
    ('wallet', 'Wallet balance'),
    ('gift', 'Gift card'),
  ];

  final _scroll = ScrollController();
  final List<WalletTransaction> _items = [];
  String _method = '';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int? _nextBefore;
  Object? _error;
  int _generation = 0; // ignores responses from a superseded filter

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) _loadMore();
    });
    _reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(walletRepositoryProvider).getTransactions(paymentMethod: _method);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.results);
        _hasMore = page.hasMore;
        _nextBefore = page.nextBefore;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients && _scroll.position.maxScrollExtent <= 0) _loadMore();
      });
    } catch (e) {
      if (mounted && gen == _generation) setState(() => _error = e);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _nextBefore == null) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(walletRepositoryProvider)
          .getTransactions(paymentMethod: _method, before: _nextBefore);
      if (!mounted || gen != _generation) return;
      setState(() {
        final seen = _items.map((t) => t.id).toSet();
        _items.addAll(page.results.where((t) => t.id == null || !seen.contains(t.id)));
        _hasMore = page.hasMore;
        _nextBefore = page.nextBefore;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setMethod(String method) {
    if (method == _method) return;
    setState(() => _method = method);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction history')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (value, label) = _methods[i];
                return ChoiceChip(
                  label: Text(label),
                  selected: _method == value,
                  onSelected: (_) => _setMethod(value),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _buildBody(scheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return DuoStateView.error(_error!, onRetry: _reload, title: 'Could not load transactions');
    }
    if (_items.isEmpty) {
      return DuoStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        message: _method.isEmpty ? 'Top-ups, purchases and gift cards will show here.' : 'Nothing for this payment method.',
      );
    }

    // Flatten into date headers + rows.
    final rows = <Object>[];
    String? lastGroup;
    for (final t in _items) {
      final g = groupLabelForDate(t.createdAt);
      if (g != lastGroup) {
        rows.add(g);
        lastGroup = g;
      }
      rows.add(t);
    }

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: rows.length + 1,
      itemBuilder: (context, i) {
        if (i == rows.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (!_hasMore) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text("You've reached the end", style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ),
            );
          }
          return const SizedBox(height: 48);
        }
        final row = rows[i];
        if (row is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
            child: Text(
              row,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant),
            ),
          );
        }
        final txn = row as WalletTransaction;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: scheme.surfaceContainerHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            onTap: () => showWalletTransactionDetail(context, txn),
            leading: CircleAvatar(
              backgroundColor:
                  txn.isCredit ? DuoColors.esewaGreen.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
              child: Icon(
                switch (txn.type) {
                  'top_up' => Icons.add_card_rounded,
                  'purchase' => Icons.workspace_premium_outlined,
                  'adjustment' => Icons.tune_rounded,
                  _ => Icons.receipt_long_rounded,
                },
                size: 20,
                color: txn.isCredit ? DuoColors.esewaGreen : scheme.onSurfaceVariant,
              ),
            ),
            title: Text(txn.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  WalletStatusBadge(txn: txn),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(formatTxnDate(txn.createdAt),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            trailing: Text(
              formatTxnAmount(txn.amount),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: txn.isCredit ? DuoColors.esewaGreen : scheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}
