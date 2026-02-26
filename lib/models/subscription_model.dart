class SubscriptionStatusModel {
  final bool hasActivePlan;
  final bool hasFreeTrial;
  final DateTime? trialEndsAt;
  final String? subscriptionStatus;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final bool canUseTrial;

  SubscriptionStatusModel({
    required this.hasActivePlan,
    required this.hasFreeTrial,
    this.trialEndsAt,
    this.subscriptionStatus,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    required this.canUseTrial,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusModel(
      hasActivePlan: json['has_active_plan'] ?? false,
      hasFreeTrial: json['has_free_trial'] ?? false,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.parse(json['trial_ends_at'])
          : null,
      subscriptionStatus: json['subscription_status'],
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
      canUseTrial: json['can_use_trial'] ?? true,
    );
  }

  bool get hasValidAccess => hasActivePlan || hasFreeTrial;

  /// User cancelled from app; plan will not renew after period end.
  bool get isCancelledByUser => cancelAtPeriodEnd;

  /// Autopay cancelled/paused from UPI/bank (Razorpay status halted).
  bool get isAutopayCancelled => subscriptionStatus == 'halted';
}

class SubscriptionCreateResponse {
  final String subscriptionId;
  final String? shortUrl;
  final String status;
  final bool hasTrial;
  final String razorpayKey;

  SubscriptionCreateResponse({
    required this.subscriptionId,
    this.shortUrl,
    required this.status,
    required this.hasTrial,
    required this.razorpayKey,
  });

  factory SubscriptionCreateResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionCreateResponse(
      subscriptionId: json['subscription_id'] ?? '',
      shortUrl: json['short_url'],
      status: json['status'] ?? '',
      hasTrial: json['has_trial'] ?? false,
      razorpayKey: json['razorpay_key'] ?? '',
    );
  }
}
