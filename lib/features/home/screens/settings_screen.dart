import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'pay_calculation_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    FocusUtils.unfocus();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => NavigationUtils.pop(true),
            child: const Text('Logout', style: TextStyle(color: AppColors.warningRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().logout();
      NavigationUtils.pushAndRemoveUntil(const LoginScreen());
      SnackbarUtils.showSuccess('Logged out successfully');
    } catch (e) {
      SnackbarUtils.showError('Failed to logout');
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    FocusUtils.unfocus();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => NavigationUtils.pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.warningRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final secondConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'This is your final warning. All your staff data, attendance records, cashbook entries, and subscription will be permanently deleted.\n\nType "DELETE" to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => NavigationUtils.pop(true),
            child: const Text('Yes, Delete Everything', style: TextStyle(color: AppColors.warningRed)),
          ),
        ],
      ),
    );

    if (secondConfirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ApiService().deleteAccount();
      NavigationUtils.pop();
      NavigationUtils.pushAndRemoveUntil(const LoginScreen());
      SnackbarUtils.showSuccess('Account deleted successfully');
    } catch (e) {
      NavigationUtils.pop();
      SnackbarUtils.showError('Failed to delete account. Please try again.');
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://nutanvij.com/staging/backend/public/privacy-policy.html');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse('mailto:sales.laborigin@gmail.com?subject=Attendex Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.access_time, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: AppTypography.titleLarge(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Version ${AppConstants.fullVersion}',
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Text(
          'Attendex helps you manage staff attendance, track expenses, and generate reports with ease.',
          style: AppTypography.bodyMedium(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationUtils.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = StorageService.getUser();
    final themeProvider = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Account Section
                if (user != null) ...[
                  _buildSectionTitle(context, 'Account'),
                  _buildSettingTile(
                    context,
                    icon: Icons.person,
                    title: 'Name',
                    subtitle: user.name,
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: user.email,
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.phone,
                    title: 'Mobile',
                    subtitle: user.mobile,
                  ),
                  _buildSettingTile(
                    context,
                    icon: Icons.business,
                    title: 'Business',
                    subtitle: user.businessName,
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Appearance Section
                _buildSectionTitle(context, 'Appearance'),
                _buildSettingTile(
                  context,
                  icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  title: 'Theme',
                  subtitle: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Info Section
                _buildSectionTitle(context, 'App Info'),
                _buildSettingTile(
                  context,
                  icon: Icons.calculate_outlined,
                  title: 'Pay Calculation Guide',
                  subtitle: 'How salary is calculated for staff',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  onTap: () => NavigationUtils.push(const PayCalculationInfoScreen()),
                  iconColor: Colors.orange,
                  iconBgColor: Colors.orange.withOpacity(0.1),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  onTap: _openPrivacyPolicy,
                  iconColor: AppColors.primaryBlue,
                  iconBgColor: AppColors.primaryBlue.withOpacity(0.1),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.mail_outline,
                  title: 'Contact Support',
                  subtitle: 'Get help from our support team',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  onTap: _contactSupport,
                  iconColor: AppColors.successGreen,
                  iconBgColor: AppColors.successGreen.withOpacity(0.1),
                ),
                _buildSettingTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'Version ${AppConstants.fullVersion}',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  onTap: () => _showAboutDialog(context),
                  iconColor: AppColors.primaryBlue,
                  iconBgColor: AppColors.primaryBlue.withOpacity(0.1),
                ),
                const SizedBox(height: 32),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      'Logout',
                      style: AppTypography.titleMedium(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.warningRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Delete Account
                Center(
                  child: TextButton.icon(
                    onPressed: () => _handleDeleteAccount(context),
                    icon: const Icon(Icons.delete_outline, color: AppColors.warningRed, size: 20),
                    label: Text(
                      'Delete Account',
                      style: AppTypography.bodyMedium(color: AppColors.warningRed, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: AppTypography.titleMedium(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
    Color? iconBgColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = textColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final effectiveIconColor = iconColor ?? AppColors.primaryBlue;
    final effectiveIconBgColor = iconBgColor ?? AppColors.primaryBlue.withOpacity(0.1);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: effectiveIconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: effectiveIconColor, size: 22),
        ),
        title: Text(
          title,
          style: AppTypography.titleMedium(color: titleColor),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTypography.bodySmall(color: subtitleColor),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
