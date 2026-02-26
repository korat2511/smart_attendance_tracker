import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_attendance_tracker/configuration/app_colors.dart';
import 'package:smart_attendance_tracker/configuration/app_constants.dart';
import 'package:smart_attendance_tracker/configuration/app_typography.dart';
import 'package:smart_attendance_tracker/utils/snackbar_utils.dart';
import 'package:smart_attendance_tracker/utils/navigation_utils.dart';

class AdvancePaymentBottomSheet extends StatefulWidget {
  final DateTime date;
  final double initialAmount;
  final String? initialNotes;
  final String? initialPaymentMethod;
  final Future<void> Function(double amount, String? notes, String paymentMethod) onSave;

  const AdvancePaymentBottomSheet({
    super.key,
    required this.date,
    this.initialAmount = 0,
    this.initialNotes,
    this.initialPaymentMethod,
    required this.onSave,
  });

  @override
  State<AdvancePaymentBottomSheet> createState() => _AdvancePaymentBottomSheetState();
}

class _AdvancePaymentBottomSheetState extends State<AdvancePaymentBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _selectedPaymentMethod;
  bool _isLoading = false;

  String get _dateString {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${widget.date.day.toString().padLeft(2, '0')} ${months[widget.date.month - 1]} ${widget.date.year}';
  }

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.initialPaymentMethod ?? AppConstants.defaultPaymentMethod;
    _amountController = TextEditingController(
      text: widget.initialAmount > 0 ? widget.initialAmount.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 0) {
      SnackbarUtils.showError('Please enter a valid amount');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.onSave(
        amount,
        _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        _selectedPaymentMethod,
      );
      if (mounted) {
        NavigationUtils.pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + bottomPadding,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Advance Payment',
              style: AppTypography.titleLarge(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _dateString,
                    style: AppTypography.bodyMedium(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Payment method',
                    style: AppTypography.labelMedium(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.paymentMethods.map((e) {
                      final isSelected = _selectedPaymentMethod == e.key;
                      return FilterChip(
                        label: Text(e.value),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedPaymentMethod = e.key),
                        selectedColor: AppColors.primaryBlue.withOpacity(0.3),
                        checkmarkColor: AppColors.primaryBlue,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.warningRed),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final a = double.tryParse(value.trim().replaceAll(',', ''));
                      if (a == null || a < 0) return 'Enter a valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Optional note for this advance',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => NavigationUtils.pop(false),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
