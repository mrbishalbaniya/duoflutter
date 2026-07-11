import 'package:equatable/equatable.dart';

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
      planId: json['plan_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      currency: json['currency'] as String? ?? 'NPR',
      amount: (json['amount'] as num).toInt(),
      durationDays: json['duration_days'] as int,
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
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      type: json['type'] as String,
      amount: json['amount'].toString(),
      balanceAfter: json['balance_after'].toString(),
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );
  }

  final String type;
  final String amount;
  final String balanceAfter;
  final String description;
  final String createdAt;

  @override
  List<Object?> get props => [type, amount, createdAt];
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
      balance: (json['balance'] as num).toInt(),
      currency: json['currency'] as String? ?? 'NPR',
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

class EsewaPaymentForm extends Equatable {
  const EsewaPaymentForm({
    required this.paymentUrl,
    required this.transactionUuid,
    required this.fields,
  });

  factory EsewaPaymentForm.fromJson(Map<String, dynamic> json) {
    return EsewaPaymentForm(
      paymentUrl: json['payment_url'] as String,
      transactionUuid: json['transaction_uuid'] as String,
      fields: Map<String, String>.from(json['form'] as Map<String, dynamic>),
    );
  }

  final String paymentUrl;
  final String transactionUuid;
  final Map<String, String> fields;

  @override
  List<Object?> get props => [transactionUuid];
}
