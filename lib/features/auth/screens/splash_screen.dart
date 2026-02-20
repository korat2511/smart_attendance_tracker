import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../screens/login_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../subscription/providers/subscription_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    await StorageService.init();
    final isLoggedIn = StorageService.isLoggedIn();

    if (isLoggedIn) {
      try {
        final subscriptionProvider = context.read<SubscriptionProvider>();
        await subscriptionProvider.checkSubscriptionStatus();
        
        if (!mounted) return;
        
        if (subscriptionProvider.hasValidAccess) {
          NavigationUtils.pushAndRemoveUntil(const HomeScreen());
        } else {
          NavigationUtils.pushAndRemoveUntil(const SubscriptionScreen());
        }
      } catch (e) {
        NavigationUtils.pushAndRemoveUntil(const HomeScreen());
      }
    } else {
      NavigationUtils.pushAndRemoveUntil(const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: ResponsiveUtils.responsive(
                context,
                mobile: 120,
                tablet: 150,
                desktop: 180,
              ),
              height: ResponsiveUtils.responsive(
                context,
                mobile: 120,
                tablet: 150,
                desktop: 180,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.access_time,
                size: ResponsiveUtils.responsive(
                  context,
                  mobile: 60,
                  tablet: 75,
                  desktop: 90,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Smart Attendance Tracker',
              style: AppTypography.displaySmall(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your team attendance',
              style: AppTypography.bodyMedium(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
