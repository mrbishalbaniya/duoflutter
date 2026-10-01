import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/wallet_models.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers/core_providers.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/duo_coin.dart';
import '../auth/auth_controller.dart';
import 'domain/wallet_domain.dart';
import 'providers/wallet_providers.dart';
import 'services/esewa_payment_service.dart';
import 'widgets/esewa_payment_webview.dart';
import 'widgets/payment_method_sheet.dart';
import 'widgets/stripe_checkout_webview.dart';
import 'widgets/wallet_gift_card_section.dart';
import 'widgets/wallet_skeleton.dart';

const _creditGreen = Color(0xFF60BB46);

/// Mirrors web `/wallet`: balance, buy coins (eSewa or card via Stripe),
/// redeem a gift card and the latest transaction.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _esewaService = EsewaPaymentService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleQueryReturn());
  }

  void _handleQueryReturn() {
    final walletResult = GoRouterState.of(context).uri.queryParameters['wallet'];
    if (walletResult != null) {
      ref.read(walletUiProvider.notifier).handleWalletReturn(walletResult);
      context.replace(AppRoutes.wallet);
    }
  }

  void _notice(String? message) => ref.read(walletUiProvider.notifier).setNotice(message);

  Future<void> _buyPack(CoinPack pack, WalletPaymentMethods methods) async {
    HapticFeedback.lightImpact();
    final method = await showPaymentMethodSheet(context, pack: pack, methods: methods);
    if (method == null || !mounted) return;
    _notice(null);
    if (method == PaymentMethod.stripe) {
      await _payWithStripe(pack.coins);
    } else {
      await _payWithEsewa(pack.coins);
    }
  }

  Future<void> _payWithStripe(int amount) async {
    try {
      final session = await ref.read(walletRepositoryProvider).initiateStripeTopUp(amount);
      if (!mounted) return;
      if (session.checkoutUrl.isEmpty) {
        _notice('Could not start card payment.');
        return;
      }
      final result = await Navigator.of(context).push<StripeCheckoutResult>(
        MaterialPageRoute(builder: (_) => StripeCheckoutScreen(checkoutUrl: session.checkoutUrl)),
      );
      if (!mounted) return;
      switch (result) {
        case StripeCheckoutResult.success:
          _notice('Coins added successfully.');
        case StripeCheckoutResult.failed:
          _notice('Coin purchase was not completed.');
        case StripeCheckoutResult.canceled || null:
          _notice('Payment was canceled.');
      }
      await ref.read(walletUiProvider.notifier).refreshAll();
    } on ApiException catch (e) {
      if (mounted) _notice(e.message);
    } catch (_) {
      if (mounted) _notice('Could not start card payment.');
    }
  }

  Future<void> _payWithEsewa(int amount) async {
    final ui = ref.read(walletUiProvider.notifier);
    EsewaPaymentForm? form;
    try {
      form = await ui.initiateTopUp(amount);
      if (!mounted) return;

      var toppedUp = false;

      if (_esewaService.supportsNativeSdk && form.mobileSdk?.isConfigured == true) {
        final nativeResult = await _esewaService.startNativePayment(form);
        ui.clearToppingUp();
        if (!mounted) return;

        if (nativeResult.outcome == EsewaPaymentOutcome.success) {
          try {
            final verified = await ref.read(walletRepositoryProvider).verifyPayment(
                  form.transactionUuid,
                  refId: nativeResult.refId,
                );
            toppedUp = verified['status'] == 'COMPLETE';
          } catch (_) {}
        } else if (nativeResult.outcome == EsewaPaymentOutcome.failure) {
          _notice('Coin purchase was not completed.');
          return;
        } else {
          _notice('Payment was canceled.');
          return;
        }
      } else {
        final success = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => EsewaPaymentScreen(form: form!)),
        );
        ui.clearToppingUp();
        if (!mounted) return;

        toppedUp = success == true;
        if (success == null && form.transactionUuid.isNotEmpty) {
          try {
            final verified = await ref.read(walletRepositoryProvider).verifyPayment(form.transactionUuid);
            toppedUp = verified['status'] == 'COMPLETE';
          } catch (_) {}
        } else if (success == false) {
          _notice('Coin purchase was not completed.');
          return;
        }
      }

      _notice(toppedUp
          ? 'Coins added successfully.'
          : 'Payment submitted. Pull to refresh if your balance has not updated yet.');
      await ref.read(walletUiProvider.notifier).refreshAll();
    } on ApiException catch (e) {
      ui.clearToppingUp();
      if (mounted && e.statusCode != 404) _notice(e.message);
    } catch (e) {
      ui.clearToppingUp();
      if (mounted) {
        _notice(e is UnsupportedError
            ? 'Native eSewa is not available on this device.'
            : 'Could not start eSewa payment.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(walletDataProvider);
    final ui = ref.watch(walletUiProvider);
    final user = ref.watch(authControllerProvider).user;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        shape: Border(bottom: BorderSide(color: scheme.primary.withValues(alpha: 0.1))),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(walletUiProvider.notifier).refreshAll(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            Text(
              'Buy coins with eSewa or card and spend them on Duo Premium from Discover.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            if (ui.notice != null) ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(ui.notice!, style: text.bodyMedium)),
                    IconButton(
                      tooltip: 'Dismiss',
                      onPressed: () => _notice(null),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            ...data.when(
              loading: () => const [SizedBox(height: 420, child: WalletSkeleton())],
              error: (e, _) => [
                _WalletError(
                  message: e is ApiException ? e.message : 'Could not load wallet.',
                  onRetry: () => ref.invalidate(walletDataProvider),
                ),
              ],
              data: (walletData) {
                final wallet = walletData.wallet;
                final balance = wallet.balance;
                final packs = wallet.coinPacks.isNotEmpty ? wallet.coinPacks : CoinPack.defaults;
                final expires = DateTime.tryParse(user?.profile.subscriptionExpiresAt ?? '');
                return [
                  if (walletData.degraded) ...[
                    Text(
                      walletData.degradedMessage ?? 'Wallet API unavailable. Backend redeploy in progress.',
                      style: TextStyle(color: scheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _BalanceCard(
                    balance: balance,
                    premiumUntil: (user?.profile.isPremium ?? false) && expires != null
                        ? DateFormat.yMMMd().format(expires.toLocal())
                        : null,
                  ),
                  const SizedBox(height: 24),
                  const _Heading('Buy coins'),
                  _Card(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final columns = c.maxWidth >= 480 ? 4 : 2;
                        const gap = 8.0;
                        final width = (c.maxWidth - gap * (columns - 1)) / columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final pack in packs)
                              SizedBox(
                                width: width,
                                child: _PackButton(
                                  pack: pack,
                                  disabled: ui.busy,
                                  onTap: () => _buyPack(pack, wallet.paymentMethods),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Heading('Redeem a gift card'),
                  const _Card(padding: EdgeInsets.all(16), child: WalletGiftCardSection()),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        const Expanded(child: _Heading('Recent activity', padded: false)),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.walletTransactions),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('View all'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _Card(
                    child: wallet.transactions.isNotEmpty
                        ? _LatestTransactionRow(txn: wallet.transactions.first)
                        : ListTile(
                            title: Text(
                              'No transactions yet',
                              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                            onTap: () => context.push(AppRoutes.walletTransactions),
                          ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {this.padded = true});

  final String title;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    return padded ? Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 12), child: label) : label;
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.1)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, this.premiumUntil});

  final int balance;
  final String? premiumUntil;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.1),
            scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your coins',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const DuoCoin(size: 34),
              const SizedBox(width: 10),
              // Counts up like web NumberFlow.
              TweenAnimationBuilder<double>(
                tween: Tween(end: balance.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  formatCoinAmount(value.round()),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          if (premiumUntil != null) ...[
            const SizedBox(height: 12),
            Text('Premium active until $premiumUntil', style: TextStyle(fontSize: 14, color: scheme.primary)),
          ],
        ],
      ),
    );
  }
}

class _PackButton extends StatelessWidget {
  const _PackButton({required this.pack, required this.disabled, required this.onTap});

  final CoinPack pack;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DuoCoin(size: 18),
                    const SizedBox(width: 6),
                    Text(formatCoinAmount(pack.coins), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatNprPrice(pack.priceNpr),
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestTransactionRow extends StatelessWidget {
  const _LatestTransactionRow({required this.txn});

  final WalletTransaction txn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push(AppRoutes.walletTransactions),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.description.isNotEmpty
                        ? txn.description
                        : switch (txn.type) {
                            'top_up' => 'Coin pack purchase',
                            'gift_redeem' => 'Gift card redeemed',
                            _ => 'Purchase',
                          },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatTxnDate(txn.createdAt),
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Text(
              formatTxnAmount(txn.amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: txn.isCredit ? _creditGreen : scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
