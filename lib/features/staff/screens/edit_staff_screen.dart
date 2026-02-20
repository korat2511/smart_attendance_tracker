import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/models/staff_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/typography/app_typography.dart';
import '../providers/staff_provider.dart';

class EditStaffScreen extends StatefulWidget {
  final StaffModel staff;

  const EditStaffScreen({
    super.key,
    required this.staff,
  });

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryAmountController = TextEditingController();
  final _overtimeChargesController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _salaryAmountFocusNode = FocusNode();
  final _overtimeChargesFocusNode = FocusNode();

  String _selectedSalaryType = 'monthly';
  bool _isLoading = false;
  bool _hasSalaryChanged = false;
  bool _hasOvertimeChanged = false;

  final List<Map<String, String>> _salaryTypes = [
    {'value': 'hourly', 'label': 'Hourly'},
    {'value': 'daily', 'label': 'Daily'},
    {'value': 'weekly', 'label': 'Weekly'},
    {'value': 'monthly', 'label': 'Monthly'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.staff.name;
    _phoneController.text = widget.staff.phoneNumber;
    _selectedSalaryType = widget.staff.salaryType;
    _salaryAmountController.text = widget.staff.salaryAmount.toStringAsFixed(2);
    _overtimeChargesController.text = widget.staff.overtimeCharges.toStringAsFixed(2);

    // Track changes to salary and overtime
    _salaryAmountController.addListener(() {
      final currentValue = double.tryParse(_salaryAmountController.text) ?? 0.0;
      if (currentValue != widget.staff.salaryAmount) {
        setState(() {
          _hasSalaryChanged = true;
        });
      } else {
        setState(() {
          _hasSalaryChanged = false;
        });
      }
    });

    _overtimeChargesController.addListener(() {
      final currentValue = double.tryParse(_overtimeChargesController.text) ?? 0.0;
      if (currentValue != widget.staff.overtimeCharges) {
        setState(() {
          _hasOvertimeChanged = true;
        });
      } else {
        setState(() {
          _hasOvertimeChanged = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryAmountController.dispose();
    _overtimeChargesController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _salaryAmountFocusNode.dispose();
    _overtimeChargesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusUtils.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final salaryAmount = double.tryParse(_salaryAmountController.text) ?? 0.0;
      final overtimeCharges = double.tryParse(_overtimeChargesController.text) ?? 0.0;

      final updatedStaff = widget.staff.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        salaryType: _selectedSalaryType,
        salaryAmount: salaryAmount,
        overtimeCharges: overtimeCharges,
      );

      await context.read<StaffProvider>().updateStaff(updatedStaff);

      if (!mounted) return;

      SnackbarUtils.showSuccess(
        'Staff member updated successfully',
      );

      NavigationUtils.pop(true);
    } catch (e) {
      if (!mounted) return;

      SnackbarUtils.showError(
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Edit Staff'),
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Staff Name *',
                      hintText: 'Enter staff name',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_phoneFocusNode);
                    },
                    validator: (value) => Validators.required(
                      value,
                      'Staff name',
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'Enter phone number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_salaryAmountFocusNode);
                    },
                    validator: (value) => Validators.required(
                      value,
                      'Phone number',
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Salary type dropdown
                  // ignore: deprecated_member_use
                  DropdownButtonFormField<String>(
                    value: _selectedSalaryType,
                    decoration: InputDecoration(
                      labelText: 'Salary Type *',
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    items: _salaryTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['value'],
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSalaryType = value;
                          if (value != widget.staff.salaryType) {
                            _hasSalaryChanged = true;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Salary amount field
                  TextFormField(
                    controller: _salaryAmountController,
                    focusNode: _salaryAmountFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Salary Amount *',
                      hintText: 'Enter salary amount',
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_overtimeChargesFocusNode);
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Salary amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  // Show note if salary changed
                  if (_hasSalaryChanged || _selectedSalaryType != widget.staff.salaryType)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'New rate will be applicable from today',
                              style: AppTypography.bodySmall(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Overtime charges field
                  TextFormField(
                    controller: _overtimeChargesController,
                    focusNode: _overtimeChargesFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Overtime Charges',
                      hintText: 'Enter overtime charges (optional)',
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(Icons.access_time),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onFieldSubmitted: (_) => _handleSubmit(),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0) {
                          return 'Please enter a valid amount';
                        }
                      }
                      return null;
                    },
                  ),
                  // Show note if overtime changed
                  if (_hasOvertimeChanged)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'New rate will be applicable from today',
                              style: AppTypography.bodySmall(
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  // Submit button
                  LoadingButton(
                    text: 'Update Staff',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
