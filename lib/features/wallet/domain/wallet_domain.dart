import 'package:intl/intl.dart';

import '../../../core/models/wallet_models.dart';

String formatCoins(int amount) {
  final formatted = NumberFormat('#,##0', 'en_NP').format(amount);
  return '$formatted coins';
}

String formatCoinAmount(int amount) {
  return NumberFormat('#,##0', 'en_NP').format(amount);
}

String formatNprPrice(int amount) {
  return 'NPR ${NumberFormat('#,##0', 'en_NP').format(amount)}';
}

String formatTxnDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return iso;
  return DateFormat('MMM d, h:mm a').format(date.toLocal());
}

String formatTxnAmount(String amount) {
  final num = double.tryParse(amount) ?? 0;
  final abs = NumberFormat('#,##0', 'en_NP').format(num.abs());
  return num >= 0 ? '+$abs coins' : '-$abs coins';
}

String groupLabelForDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return 'Earlier';
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('MMMM d, yyyy').format(local);
}

List<WalletTransaction> filterTransactions(
  List<WalletTransaction> items,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((txn) {
    return txn.displayTitle.toLowerCase().contains(q) ||
        txn.type.toLowerCase().contains(q) ||
        txn.referenceId.toLowerCase().contains(q) ||
        txn.amount.contains(q);
  }).toList();
}

Map<String, List<WalletTransaction>> groupTransactionsByDate(
  List<WalletTransaction> items,
) {
  final grouped = <String, List<WalletTransaction>>{};
  for (final txn in items) {
    final label = groupLabelForDate(txn.createdAt);
    grouped.putIfAbsent(label, () => []).add(txn);
  }
  return grouped;
}

String premiumExpiryLabel(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final date = DateTime.tryParse(iso);
  if (date == null) return '';
  return DateFormat('MMM d, yyyy').format(date.toLocal());
}
