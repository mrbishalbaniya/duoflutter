import 'package:equatable/equatable.dart';

import '../config/app_config.dart';

class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.planId,
    required this.name,
    required this.description,
    required this.currency,
    required this.amount,
    required this.durationDays,
    this.badge,
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
    );
  }

  final String planId;
  final String name;
  final String description;
  final String currency;
  final int amount;
  final int durationDays;
  final String? badge;

  @override
  List<Object?> get props => [planId];
}

class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
    this.referenceId = '',
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      type: json['type'] as String? ?? 'adjustment',
      amount: '${json['amount'] ?? 0}',
      balanceAfter: '${json['balance_after'] ?? 0}',
      description: json['description'] as String? ?? '',
      createdAt: '${json['created_at'] ?? ''}',
      referenceId: json['reference_id'] as String? ?? '',
    );
  }

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
      'purchase' => 'Premium purchase',
      'adjustment' => 'Balance adjustment',
      _ => 'Transaction',
    };
  }

  @override
  List<Object?> get props => [type, amount, createdAt, referenceId];
}

class WalletSummary extends Equatable {
  const WalletSummary({
    required this.balance,
    required this.currency,
    required this.topUpPresets,
    required this.transactions,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
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

  @override
  List<Object?> get props => [balance, transactions.length];
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
