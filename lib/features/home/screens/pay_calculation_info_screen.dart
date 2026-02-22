import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/typography/app_typography.dart';

class PayCalculationInfoScreen extends StatelessWidget {
  const PayCalculationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        title: const Text('Pay Calculation Guide'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(isDark),
            const SizedBox(height: 24),
            _buildSalaryTypeCard(
              isDark: isDark,
              title: 'Hourly Rate',
              icon: Icons.access_time,
              color: Colors.blue,
              formula: 'Total Pay = (Worked Hours × Hourly Rate) + (OT Hours × OT Rate)',
              description: 'Payment is calculated based on actual hours worked. You can enter hours using:',
              bulletPoints: [
                'Check-in/Check-out times - Hours are calculated automatically',
                'Manual Hours - Enter worked hours directly',
                'Overtime hours are tracked separately and paid at OT rate',
              ],
              example: 'Example: 8 hrs × ₹200/hr + 2 OT hrs × ₹300/hr = ₹1,600 + ₹600 = ₹2,200',
            ),
            const SizedBox(height: 16),
            _buildSalaryTypeCard(
              isDark: isDark,
              title: 'Daily Rate',
              icon: Icons.calendar_today,
              color: Colors.green,
              formula: 'Total Pay = (Present Days × Daily Rate) + (Half Days × 50%) + OT',
              description: 'Payment is calculated based on the number of days worked:',
              bulletPoints: [
                'Full Present (P) = 100% of daily rate',
                'Half Day (HD) = 50% of daily rate',
                'Absent (A) / Off = No payment',
                'Check-in/out times are optional (for records only)',
              ],
              example: 'Example: 20 days × ₹500 + 2 half days × ₹250 = ₹10,000 + ₹500 = ₹10,500',
            ),
            const SizedBox(height: 16),
            _buildSalaryTypeCard(
              isDark: isDark,
              title: 'Weekly Rate',
              icon: Icons.date_range,
              color: Colors.orange,
              formula: 'Total Pay = (Working Days ÷ 7) × Weekly Rate + OT',
              description: 'Payment is calculated based on weeks worked:',
              bulletPoints: [
                'Full week (7 days) = 100% of weekly rate',
                'Partial weeks are prorated based on days present',
                'Half days count as 0.5 days',
                'Check-in/out times are optional',
              ],
              example: 'Example: 25 days ÷ 7 × ₹3,500 = 3.57 weeks × ₹3,500 = ₹12,500',
            ),
            const SizedBox(height: 16),
            _buildSalaryTypeCard(
              isDark: isDark,
              title: 'Monthly Rate',
              icon: Icons.calendar_month,
              color: Colors.purple,
              formula: 'Total Pay = (Working Days ÷ Working Days in Month) × Monthly Rate + OT',
              description: 'Payment is prorated based on attendance. Off days (holidays/week off) are not counted:',
              bulletPoints: [
                'Working days in month = Days in month − Off days marked',
                'Full attendance on working days = 100% of monthly salary',
                'Half days count as 0.5 days',
                'Check-in/out times are optional',
              ],
              example: 'Example: January has 31 days, 2 off days → 29 working days. 22 present ÷ 29 × ₹15,000 = ₹11,379',
            ),
            const SizedBox(height: 24),
            _buildOffDaysSection(isDark),
            const SizedBox(height: 24),
            _buildPayMultiplierSection(isDark),
            const SizedBox(height: 24),
            _buildOvertimeSection(isDark),
            const SizedBox(height: 24),
            _buildAdvanceSection(isDark),
            const SizedBox(height: 24),
            _buildTipsSection(isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                'How Pay is Calculated',
                style: AppTypography.titleLarge(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Attendex supports 4 salary types. Each type has its own calculation method. '
            'This guide explains how payment is calculated for each type.',
            style: AppTypography.bodyMedium(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTypeCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required String formula,
    required String description,
    required List<String> bulletPoints,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.surfaceDark : Colors.grey[300]!,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.titleMedium(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.functions, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formula,
                    style: AppTypography.bodyMedium(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          ...bulletPoints.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        point,
                        style: AppTypography.bodySmall(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    example,
                    style: AppTypography.bodySmall(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffDaysSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy, color: Colors.teal, size: 24),
              const SizedBox(width: 12),
              Text(
                'Off Days (Holidays / Week Off)',
                style: AppTypography.titleMedium(
                  color: Colors.teal[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'For monthly staff, any day marked as "Off" (holiday, week off) is not counted in the working days. '
            'Pay is prorated using working days = days in month − off days.',
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working days in month = Days in month − Off days',
                  style: AppTypography.bodyMedium(
                    color: Colors.teal[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: January has 31 days. If you mark 2 days as Off (e.g. Republic Day, Sunday off), '
                  'working days = 29. Pay is then (Present + Half×0.5) ÷ 29 × Monthly rate.',
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayMultiplierSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              Text(
                'Pay Multiplier',
                style: AppTypography.titleMedium(
                  color: Colors.purple[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Use Pay Multiplier for special pay rates on specific days:',
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _buildMultiplierExample(isDark, '1.0x', 'Normal pay (default)'),
          _buildMultiplierExample(isDark, '1.5x', 'Time and a half (e.g., Saturday)'),
          _buildMultiplierExample(isDark, '2.0x', 'Double pay (e.g., Sunday/Holiday)'),
          _buildMultiplierExample(isDark, 'Custom', 'Any value like 2.5x, 3x, etc.'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formula:',
                  style: AppTypography.bodySmall(
                    color: Colors.purple[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day Pay = (Base Daily Pay × Multiplier) + Overtime',
                  style: AppTypography.bodyMedium(
                    color: Colors.purple[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Example: ₹500/day × 2.0x = ₹1,000 for that day',
                  style: AppTypography.bodySmall(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Multiplier applies to basic pay only, not overtime.',
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierExample(bool isDark, String multiplier, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              multiplier,
              style: AppTypography.bodySmall(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.more_time, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Overtime (OT)',
                style: AppTypography.titleMedium(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Overtime is calculated separately and added to the base pay:',
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'OT Pay = OT Hours × OT Rate (set per staff)',
            style: AppTypography.bodyMedium(
              color: Colors.orange[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: When marking P+OT, the day is counted as Present plus additional overtime hours.',
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.money_off, color: AppColors.warningRed, size: 24),
              const SizedBox(width: 12),
              Text(
                'Advance Deduction',
                style: AppTypography.titleMedium(
                  color: AppColors.warningRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Any advance payments given to staff are automatically deducted from the net pay:',
            style: AppTypography.bodyMedium(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Net Pay = Total Earnings - Advance Payments',
            style: AppTypography.bodyMedium(
              color: AppColors.warningRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Advances are also recorded in the Cashbook as expenses.',
            style: AppTypography.bodySmall(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.successGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                'Tips',
                style: AppTypography.titleMedium(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            isDark,
            'For hourly staff, always enter check-in/out times or manual hours for accurate pay calculation.',
          ),
          _buildTipItem(
            isDark,
            'Use the Labor Report to view detailed payment breakdown for each staff member.',
          ),
          _buildTipItem(
            isDark,
            'Half Day (HD) is always calculated as 50% of the daily equivalent.',
          ),
          _buildTipItem(
            isDark,
            'Set the OT rate when adding/editing staff to track overtime pay correctly.',
          ),
          _buildTipItem(
            isDark,
            'Use Pay Multiplier (2x) for Sunday/Holiday work to pay double automatically.',
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
