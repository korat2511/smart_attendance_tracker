import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../typography/app_typography.dart';
import '../utils/navigation_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/focus_utils.dart';
import 'loading_button.dart';

class InternetErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const InternetErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 80,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Internet Connection',
                  style: AppTypography.headlineMedium(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your internet connection and try again.',
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  text: 'Retry',
                  onPressed: () {
                    FocusUtils.unfocus();
                    if (onRetry != null) {
                      onRetry!();
                    } else {
                      NavigationUtils.pop();
                    }
                  },
                  width: ResponsiveUtils.responsive(
                    context,
                    mobile: double.infinity,
                    tablet: 300,
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

class ServerErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const ServerErrorScreen({super.key, this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.warningRed,
                ),
                const SizedBox(height: 24),
                Text(
                  'Server Error',
                  style: AppTypography.headlineMedium(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message ?? 'Something went wrong on our end. Please try again later.',
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  text: 'Retry',
                  onPressed: () {
                    FocusUtils.unfocus();
                    if (onRetry != null) {
                      onRetry!();
                    } else {
                      NavigationUtils.pop();
                    }
                  },
                  width: ResponsiveUtils.responsive(
                    context,
                    mobile: double.infinity,
                    tablet: 300,
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
