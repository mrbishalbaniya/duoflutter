import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../widgets/duo_ui.dart';
import '../../auth/auth_controller.dart';
import '../domain/wallet_domain.dart';
import '../providers/wallet_providers.dart';

/// Uppercase A–Z/0–9, max 16 chars, grouped as XXXX-XXXX-XXXX-XXXX (web formatGiftCodeInput).
class _GiftCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final clipped = cleaned.length > 16 ? cleaned.substring(0, 16) : cleaned;
    final groups = <String>[];
    for (var i = 0; i < clipped.length; i += 4) {
      groups.add(clipped.substring(i, i + 4 > clipped.length ? clipped.length : i + 4));
    }
    final text = groups.join('-');
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Redeem a Duo gift card (web WalletPage "Redeem a gift card" + confirm dialog).
class WalletGiftCardSection extends ConsumerStatefulWidget {
  const WalletGiftCardSection({super.key});

  @override
  ConsumerState<WalletGiftCardSection> createState() => _WalletGiftCardSectionState();
}

class _WalletGiftCardSectionState extends ConsumerState<WalletGiftCardSection> {
  final _controller = TextEditingController();
  bool _redeeming = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _redeeming) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _success = null;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem this gift card?'),
        content: Text.rich(
          TextSpan(
            text: "You're about to redeem ",
            children: [
              TextSpan(
                text: code,
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
              const TextSpan(text: '. Each code can only be used once.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, redeem')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _redeeming = true);
    try {
      final result = await ref.read(walletRepositoryProvider).redeemGiftCard(code);
      if (!mounted) return;
      _controller.clear();
      setState(() => _success = '+${formatCoinAmount(result.amount)} coins added to your wallet!');
      ref.invalidate(walletDataProvider);
      await ref.read(authControllerProvider.notifier).refreshUser();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyErrorMessage(e, fallback: 'Could not redeem this code.'));
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = !_redeeming && _controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_redeeming,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                inputFormatters: [_GiftCodeFormatter()],
                onSubmitted: (_) => _redeem(),
                onChanged: (_) {
                  if (_error != null || _success != null) {
                    setState(() {
                      _error = null;
                      _success = null;
                    });
                  }
                },
                style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                  hintStyle: TextStyle(
                    letterSpacing: 2,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: scheme.surface.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Opacity(
              opacity: canSubmit ? 1 : 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: context.duo.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canSubmit ? _redeem : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      child: Text(
                        _redeeming ? 'Redeeming…' : 'Redeem',
                        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_error != null || _success != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error ?? _success!,
              style: TextStyle(fontSize: 14, color: _error != null ? scheme.error : const Color(0xFF60BB46)),
            ),
          ),
      ],
    );
  }
}
