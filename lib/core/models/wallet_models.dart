import 'package:equatable/equatable.dart';

import '../config/app_config.dart';

/// Premium lists that are sold separately. Values match the backend.
abstract final class SubscriptionFeature {
  static const whoLikedYou = 'who_liked_you';
  static const visitedYou = 'visited_you';
  static const rewind = 'rewind';
  static const unlimitedLikes = 'unlimited_likes';
}

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.planId,
    required this.name,
    required this.description,
    required this.currency,
    required this.amount,
    required this.durationDays,
    this.badge,
    this.feature = SubscriptionFeature.whoLikedYou,
    this.featureLabel,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      planId: json['plan_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Premium',
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? 'COIN',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      durationDays: json['duration_days'] as int? ?? 0,
      badge: json['badge'] as String?,
      feature: json['feature'] as String? ?? SubscriptionFeature.whoLikedYou,
      featureLabel: json['feature_label'] as String?,
    );
  }

  final String planId;
  final String name;
  final String description;
  final String currency;
  final int amount;
  final int durationDays;
  final String? badge;

  /// Premium list this plan unlocks, see [SubscriptionFeature].
  final String feature;
  final String? featureLabel;

  @override
  List<Object?> get props => [planId];
}

class WalletTransaction extends Equatable {
  const WalletTransaction({
    this.id,
    this.status = 'complete',
    this.paymentMethod = '',
    this.totalAmount = '',
    this.updatedAt = '',
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
    this.referenceId = '',
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'complete',
      paymentMethod: json['payment_method'] as String? ?? '',
      totalAmount: '${json['total_amount'] ?? ''}',
      updatedAt: '${json['updated_at'] ?? ''}',
      type: json['type'] as String? ?? 'adjustment',
      amount: '${json['amount'] ?? 0}',
      balanceAfter: '${json['balance_after'] ?? 0}',
      description: json['description'] as String? ?? '',
      createdAt: '${json['created_at'] ?? ''}',
      referenceId: json['reference_id'] as String? ?? '',
    );
  }

  /// Server id (used for `/wallet/transactions/<id>/`); null on very old payloads.
  final int? id;

  /// complete | pending | failed
  final String status;

  /// esewa | wallet | gift | ''
  final String paymentMethod;
  final String totalAmount;
  final String updatedAt;
  final String type;
  final String amount;
  final String balanceAfter;
  final String description;
  final String createdAt;
  final String referenceId;

  bool get isCredit {
    final value = double.tryParse(amount);
    return value != null && value >= 0;
  }

  String get displayTitle {
    if (description.isNotEmpty) return description;
    return switch (type) {
      'top_up' => 'Coin pack purchase',
      'gift_redeem' => 'Gift card redeemed',
      'purchase' => 'Premium purchase',
      'adjustment' => 'Balance adjustment',
      _ => 'Transaction',
    };
  }

  @override
  List<Object?> get props => [id, type, amount, createdAt, referenceId, status];

  String get statusLabel => switch (status) {
        'pending' => 'Pending',
        'failed' => 'Failed',
        _ => 'Completed',
      };

  String get paymentMethodLabel => switch (paymentMethod) {
        'esewa' => 'eSewa',
        'stripe' => 'Card (Stripe)',
        'wallet' => 'Wallet balance',
        'gift' => 'Gift card',
        '' => '—',
        _ => paymentMethod,
      };
}

/// One page of `GET /wallet/transactions/` (cursor = `next_before`).
class WalletTransactionPage {
  const WalletTransactionPage({required this.results, required this.hasMore, this.nextBefore});

  factory WalletTransactionPage.fromJson(Map<String, dynamic> json) {
    return WalletTransactionPage(
      results: (json['results'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      hasMore: json['has_more'] as bool? ?? false,
      nextBefore: (json['next_before'] as num?)?.toInt(),
    );
  }

  final List<WalletTransaction> results;
  final bool hasMore;
  final int? nextBefore;
}

/// Response of `POST /wallet/giftcard/redeem/`.
class GiftCardRedeemResult {
  const GiftCardRedeemResult({required this.message, required this.amount, required this.balance});

  factory GiftCardRedeemResult.fromJson(Map<String, dynamic> json) => GiftCardRedeemResult(
        message: json['detail'] as String? ?? 'Gift card redeemed.',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        balance: (json['balance'] as num?)?.toInt() ?? 0,
      );

  final String message;
  final int amount;
  final int balance;
}

class WalletSummary extends Equatable {
  const WalletSummary({
    required this.balance,
    required this.currency,
    required this.topUpPresets,
    required this.transactions,
    this.coinPacks = const [],
    this.paymentMethods = const WalletPaymentMethods(),
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: ((json['coins'] ?? json['balance']) as num?)?.toInt() ?? 0,
      coinPacks: (json['coin_packs'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CoinPack.fromJson)
          .toList(),
      paymentMethods: json['payment_methods'] is Map<String, dynamic>
          ? WalletPaymentMethods.fromJson(json['payment_methods'] as Map<String, dynamic>)
          : const WalletPaymentMethods(),
      currency: json['currency'] as String? ?? 'COIN',
      topUpPresets: (json['top_up_presets'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int balance;
  final String currency;
  final List<int> topUpPresets;
  final List<WalletTransaction> transactions;

  /// Packs the server sells; empty on older backends (use [CoinPack.defaults]).
  final List<CoinPack> coinPacks;
  final WalletPaymentMethods paymentMethods;

  @override
  List<Object?> get props => [balance, transactions.length, coinPacks.length, paymentMethods];
}

/// A coin pack from `/wallet/` `coin_packs` (web `CoinPack`).
class CoinPack extends Equatable {
  const CoinPack({required this.id, required this.coins, required this.priceNpr, this.label = ''});

  factory CoinPack.fromJson(Map<String, dynamic> json) => CoinPack(
        id: json['id'] as String? ?? 'coins_${json['coins']}',
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        priceNpr: (json['price_npr'] as num?)?.toInt() ?? (json['coins'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
      );

  final String id;
  final int coins;
  final int priceNpr;
  final String label;

  /// Same fallback list as web `DEFAULT_COIN_PACKS`.
  static const defaults = [
    CoinPack(id: 'coins_50', coins: 50, priceNpr: 50),
    CoinPack(id: 'coins_100', coins: 100, priceNpr: 100),
    CoinPack(id: 'coins_250', coins: 250, priceNpr: 250),
    CoinPack(id: 'coins_500', coins: 500, priceNpr: 500),
    CoinPack(id: 'coins_1000', coins: 1000, priceNpr: 1000),
    CoinPack(id: 'coins_2000', coins: 2000, priceNpr: 2000),
    CoinPack(id: 'coins_3000', coins: 3000, priceNpr: 3000),
    CoinPack(id: 'coins_5000', coins: 5000, priceNpr: 5000),
  ];

  @override
  List<Object?> get props => [id, coins, priceNpr];
}

/// Which top-up gateways the server has enabled (web `WalletPaymentMethods`).
class WalletPaymentMethods extends Equatable {
  const WalletPaymentMethods({
    this.esewa = true,
    this.stripe = false,
    this.stripeCurrency = 'NPR',
    this.stripeMinAmount = 0,
  });

  factory WalletPaymentMethods.fromJson(Map<String, dynamic> json) => WalletPaymentMethods(
        esewa: json['esewa'] as bool? ?? true,
        stripe: json['stripe'] as bool? ?? false,
        stripeCurrency: (json['stripe_currency'] as String? ?? '').isEmpty
            ? 'NPR'
            : (json['stripe_currency'] as String).toUpperCase(),
        stripeMinAmount: (json['stripe_min_amount'] as num?)?.toInt() ?? 0,
      );

  final bool esewa;
  final bool stripe;
  final String stripeCurrency;
  final int stripeMinAmount;

  @override
  List<Object?> get props => [esewa, stripe, stripeCurrency, stripeMinAmount];
}

/// Response of `POST /wallet/topup/stripe/`.
class StripeCheckout {
  const StripeCheckout({required this.checkoutUrl, this.sessionId = '', this.transactionUuid = ''});

  factory StripeCheckout.fromJson(Map<String, dynamic> json) => StripeCheckout(
        checkoutUrl: json['checkout_url'] as String? ?? '',
        sessionId: json['session_id'] as String? ?? '',
        transactionUuid: json['transaction_uuid'] as String? ?? '',
      );

  final String checkoutUrl;
  final String sessionId;
  final String transactionUuid;
}

class EsewaMobileSdkConfig extends Equatable {
  const EsewaMobileSdkConfig({
    required this.environment,
    required this.clientId,
    required this.secretId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    this.callbackUrl = '',
  });

  factory EsewaMobileSdkConfig.fromJson(Map<String, dynamic> json) {
    final clientId = (json['client_id'] as String? ?? '').trim().isNotEmpty
        ? (json['client_id'] as String).trim()
        : AppConfig.esewaMobileClientId;
    final secretId = (json['secret_id'] as String? ?? '').trim().isNotEmpty
        ? (json['secret_id'] as String).trim()
        : AppConfig.esewaMobileSecretId;
    final environment = (json['environment'] as String? ?? '').trim().isNotEmpty
        ? (json['environment'] as String).trim()
        : AppConfig.esewaMobileEnvironment;
    return EsewaMobileSdkConfig(
      environment: environment,
      clientId: clientId,
      secretId: secretId,
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Duo Wallet Top-up',
      productPrice: json['product_price'] as String? ?? '0',
      callbackUrl: json['callback_url'] as String? ?? '',
    );
  }

  final String environment;
  final String clientId;
  final String secretId;
  final String productId;
  final String productName;
  final String productPrice;
  final String callbackUrl;

  bool get isConfigured => clientId.isNotEmpty && secretId.isNotEmpty;

  @override
  List<Object?> get props => [productId, productPrice];
}

class EsewaPaymentForm extends Equatable {
  const EsewaPaymentForm({
    required this.paymentUrl,
    required this.transactionUuid,
    required this.fields,
    this.mobileSdk,
  });

  factory EsewaPaymentForm.fromJson(Map<String, dynamic> json) {
    final rawForm = json['form'];
    final fields = <String, String>{};
    if (rawForm is Map) {
      for (final entry in rawForm.entries) {
        fields['${entry.key}'] = '${entry.value}';
      }
    }
    final rawMobile = json['mobile_sdk'];
    return EsewaPaymentForm(
      paymentUrl: json['payment_url'] as String? ?? '',
      transactionUuid: json['transaction_uuid'] as String? ?? '',
      fields: fields,
      mobileSdk: rawMobile is Map<String, dynamic>
          ? EsewaMobileSdkConfig.fromJson(rawMobile)
          : null,
    );
  }

  final String paymentUrl;
  final String transactionUuid;
  final Map<String, String> fields;
  final EsewaMobileSdkConfig? mobileSdk;

  @override
  List<Object?> get props => [transactionUuid];
}

class WalletPurchaseResult extends Equatable {
  const WalletPurchaseResult({
    required this.isPremium,
    required this.balance,
    required this.plan,
    this.expiresAt,
  });

  factory WalletPurchaseResult.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'];
    return WalletPurchaseResult(
      isPremium: json['is_premium'] as bool? ?? false,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      expiresAt: json['expires_at'] as String?,
      plan: planJson is Map<String, dynamic>
          ? SubscriptionPlan.fromJson(planJson)
          : const SubscriptionPlan(
              planId: '',
              name: 'Premium',
              description: '',
              currency: 'COIN',
              amount: 0,
              durationDays: 0,
            ),
    );
  }

  final bool isPremium;
  final int balance;
  final String? expiresAt;
  final SubscriptionPlan plan;

  @override
  List<Object?> get props => [balance, plan.planId];
}
