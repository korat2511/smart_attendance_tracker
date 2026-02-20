import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/models/subscription_model.dart';
import '../../../core/services/api_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  Razorpay? _razorpay;

  SubscriptionStatusModel? _status;
  bool _isLoading = false;
  String? _error;
  bool _isProcessingPayment = false;

  SubscriptionStatusModel? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProcessingPayment => _isProcessingPayment;

  bool get hasValidAccess => _status?.hasValidAccess ?? false;
  bool get canUseTrial => _status?.canUseTrial ?? true;

  void Function()? _onPaymentSuccess;
  void Function(String)? _onPaymentError;

  SubscriptionProvider() {
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> checkSubscriptionStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _status = await _apiService.getSubscriptionStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startSubscription({
    required String userName,
    required String userEmail,
    required String userMobile,
    void Function()? onSuccess,
    void Function(String)? onError,
  }) async {
    _isProcessingPayment = true;
    _error = null;
    _onPaymentSuccess = onSuccess;
    _onPaymentError = onError;
    notifyListeners();

    try {
      final response = await _apiService.createSubscription();

      final options = {
        'key': response.razorpayKey,
        'subscription_id': response.subscriptionId,
        'name': 'AttendEx',
        'description': response.hasTrial
            ? '7-Day Free Trial + ₹199/month'
            : '₹199/month Subscription',
        'prefill': {
          'name': userName,
          'email': userEmail,
          'contact': userMobile,
        },
        'theme': {
          'color': '#1A73E8',
        },
      };

      _razorpay!.open(options);
    } catch (e) {
      _isProcessingPayment = false;
      _error = e.toString();
      notifyListeners();
      onError?.call(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _isProcessingPayment = false;
    notifyListeners();

    await checkSubscriptionStatus();
    _onPaymentSuccess?.call();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isProcessingPayment = false;
    _error = response.message ?? 'Payment failed';
    notifyListeners();
    _onPaymentError?.call(_error!);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  Future<void> cancelSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.cancelSubscription();
      await checkSubscriptionStatus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }
}
