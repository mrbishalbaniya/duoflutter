import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/wallet_models.dart';
import '../../../core/widgets/duo_coin.dart';
import '../domain/wallet_domain.dart';
import 'esewa_logo.dart';

enum PaymentMethod { esewa, stripe }

const _esewaGreen = Color(0xFF60BB46);
const _stripePurple = Color(0xFF635BFF);

/// Price label for a pack in the chosen method's currency (web `formatMethodPrice`).
String formatMethodPrice(int price, PaymentMethod method, WalletPaymentMethods methods) {
  if (method == PaymentMethod.stripe && methods.stripeCurrency != 'NPR') {
    return NumberFormat.simpleCurrency(name: methods.stripeCurrency).format(price);
  }
  return formatNprPrice(price);
}

/// Web `PaymentMethodSheet`: choose eSewa or card (Stripe) for a coin pack.
/// Resolves to the chosen method, or null if dismissed.
Future<PaymentMethod?> showPaymentMethodSheet(
  BuildContext context, {
  required CoinPack pack,
  required WalletPaymentMethods methods,
}) {
  return showModalBottomSheet<PaymentMethod>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _PaymentMethodSheet(pack: pack, methods: methods),
  );
}

class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet({required this.pack, required this.methods});

  final CoinPack pack;
  final WalletPaymentMethods methods;

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  PaymentMethod _method = PaymentMethod.esewa;

  bool _enabled(PaymentMethod m) => switch (m) {
        PaymentMethod.esewa => widget.methods.esewa,
        PaymentMethod.stripe => widget.methods.stripe && widget.pack.priceNpr >= widget.methods.stripeMinAmount,
      };

  bool _shown(PaymentMethod m) => switch (m) {
        PaymentMethod.esewa => widget.methods.esewa,
        PaymentMethod.stripe => widget.methods.stripe,
      };

  PaymentMethod? get _selected {
    if (_enabled(_method)) return _method;
    for (final m in PaymentMethod.values) {
      if (_enabled(m)) return m;
    }
    return null;
  }

  String _label(PaymentMethod m) => m == PaymentMethod.esewa ? 'eSewa' : 'Card';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final selected = _selected;
    final priceLabel = formatMethodPrice(widget.pack.priceNpr, selected ?? PaymentMethod.esewa, widget.methods);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
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
          ),
          const SizedBox(height: 10),
          Text('Choose payment method', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Coins are added to your wallet right after payment.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const DuoCoin(size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${formatCoinAmount(widget.pack.coins)} coins',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(priceLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final m in PaymentMethod.values)
                  if (_shown(m))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MethodTile(
                        method: m,
                        label: _label(m),
                        hint: m == PaymentMethod.stripe && !_enabled(m)
                            ? 'Available from ${formatCoinAmount(widget.methods.stripeMinAmount)} coins'
                            : m == PaymentMethod.esewa
                                ? 'Wallet & mobile banking in Nepal'
                                : 'Visa, Mastercard & more via Stripe',
                        active: selected == m,
                        enabled: _enabled(m),
                        onTap: () => setState(() => _method = m),
                      ),
                    ),
                FilledButton(
                  onPressed: selected == null ? null : () => Navigator.pop(context, selected),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  child: Text(selected == null ? 'No payment method available' : 'Pay $priceLabel with ${_label(selected)}'),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will finish payment on a secure checkout page',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.label,
    required this.hint,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final PaymentMethod method;
  final String label;
  final String hint;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final esewa = method == PaymentMethod.esewa;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: active ? scheme.primary.withValues(alpha: 0.08) : scheme.surface.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: active ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (esewa ? _esewaGreen : _stripePurple).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: esewa
                        ? const EsewaLogo(size: 28)
                        : const Icon(Icons.credit_card_rounded, color: Color(0xFF8B85FF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(hint, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
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
                      opacity: active ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
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
      ),
    );
  }
}
