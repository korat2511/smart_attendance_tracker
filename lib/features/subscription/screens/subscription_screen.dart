import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../home/screens/home_screen.dart';
import '../providers/subscription_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().checkSubscriptionStatus();
    });
  }

  void _handleSubscribe() {
    final user = StorageService.getUser();
    if (user == null) return;

    context.read<SubscriptionProvider>().startSubscription(
      userName: user.name,
      userEmail: user.email,
      userMobile: user.mobile,
      onSuccess: () {
        NavigationUtils.pushAndRemoveUntil(const HomeScreen());
      },
      onError: (error) {
        SnackbarUtils.showError(error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final canUseTrial = provider.canUseTrial;

          return Stack(
            children: [
              // Background gradient
              Container(
                height: screenHeight * 0.45,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A73E8),
                      Color(0xFF6C63FF),
                    ],
                  ),
                ),
              ),
              
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'PRO',
                                  style: AppTypography.labelMedium(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    
                    // Title section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Upgrade to Pro',
                            style: AppTypography.displaySmall(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unlock all premium features and\ntake your business to the next level',
                            style: AppTypography.bodyMedium(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Main content card
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: Column(
                            children: [
                              // Pricing card
                              _buildPricingCard(isDark, canUseTrial),
                              const SizedBox(height: 28),
                              
                              // Features
                              _buildFeaturesList(isDark),
                              const SizedBox(height: 28),
                              
                              // Subscribe button
                              _buildSubscribeButton(provider, canUseTrial),
                              const SizedBox(height: 20),
                              
                              // Payment methods & terms
                              _buildFooter(isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPricingCard(bool isDark, bool canUseTrial) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: canUseTrial
              ? [const Color(0xFF10B981), const Color(0xFF059669)]
              : [const Color(0xFF1A73E8), const Color(0xFF6C63FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (canUseTrial ? const Color(0xFF10B981) : AppColors.primaryBlue).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (canUseTrial) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'LIMITED TIME OFFER',
                    style: AppTypography.labelSmall(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '₹',
                  style: AppTypography.headlineMedium(color: Colors.white70),
                ),
              ),
              Text(
                canUseTrial ? '10' : '199',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (canUseTrial) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '7 Days Free Trial',
                    style: AppTypography.titleMedium(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Then ₹199/month',
                    style: AppTypography.bodySmall(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'per month',
              style: AppTypography.bodyMedium(color: Colors.white70),
            ),
          ],
          
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cancel anytime',
                style: AppTypography.bodySmall(color: Colors.white70),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.check_circle, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Secure payment',
                style: AppTypography.bodySmall(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(bool isDark) {
    final features = [
      {'icon': Icons.people_alt_rounded, 'title': 'Unlimited Staff Members'},
      {'icon': Icons.calendar_today_rounded, 'title': 'Complete Attendance Tracking'},
      {'icon': Icons.account_balance_wallet_rounded, 'title': 'Cashbook & Expense Management'},
      {'icon': Icons.bar_chart_rounded, 'title': 'Detailed Reports & Analytics'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Everything you need',
              style: AppTypography.titleMedium(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  feature['title'] as String,
                  style: AppTypography.bodyLarge(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSubscribeButton(SubscriptionProvider provider, bool canUseTrial) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF6C63FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: provider.isProcessingPayment ? null : _handleSubscribe,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: provider.isProcessingPayment
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    canUseTrial ? 'Start Free Trial' : 'Subscribe Now',
                    style: AppTypography.titleMedium(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (canUseTrial) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₹10',
                        style: AppTypography.labelMedium(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPaymentBadge(Icons.account_balance, 'UPI', isDark),
            const SizedBox(width: 12),
            _buildPaymentBadge(Icons.credit_card, 'Cards', isDark),
            const SizedBox(width: 12),
            _buildPaymentBadge(Icons.phone_android, 'Wallets', isDark),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              'Secured by Razorpay',
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'By subscribing, you agree to our Terms of Service and Privacy Policy',
          style: AppTypography.bodySmall(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
