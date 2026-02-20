import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/focus_utils.dart';
import '../../../core/typography/app_typography.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/error_screens.dart';
import '../../home/screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _staffSizeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _mobileFocusNode = FocusNode();
  final _businessNameFocusNode = FocusNode();
  final _staffSizeFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Clear focus when screen is mounted to prevent auto-focus on return
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusUtils.unfocus();
        _nameFocusNode.unfocus();
        _emailFocusNode.unfocus();
        _mobileFocusNode.unfocus();
        _businessNameFocusNode.unfocus();
        _staffSizeFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        _confirmPasswordFocusNode.unfocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear focus when route becomes active (e.g., when navigating back)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusUtils.unfocus();
        _nameFocusNode.unfocus();
        _emailFocusNode.unfocus();
        _mobileFocusNode.unfocus();
        _businessNameFocusNode.unfocus();
        _staffSizeFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        _confirmPasswordFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _businessNameController.dispose();
    _staffSizeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _mobileFocusNode.dispose();
    _businessNameFocusNode.dispose();
    _staffSizeFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    
    FocusUtils.unfocus();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    FocusUtils.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final staffSize = int.tryParse(_staffSizeController.text.trim()) ?? 0;
      
      final response = await ApiService().signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        businessName: _businessNameController.text.trim(),
        staffSize: staffSize,
        password: _passwordController.text,
      );

      if (response.user != null && response.token != null) {
        await StorageService.saveToken(response.token!);
        await StorageService.saveUser(response.user!);

        if (!mounted) return;
        NavigationUtils.pushAndRemoveUntil(const HomeScreen());
        SnackbarUtils.showSuccess('Account created successfully');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      
      if (e.type == ApiExceptionType.noInternet) {
        NavigationUtils.push(InternetErrorScreen(onRetry: _handleSignup));
      } else if (e.type == ApiExceptionType.serverError) {
        NavigationUtils.push(ServerErrorScreen(onRetry: _handleSignup, message: e.message));
      } else {
        SnackbarUtils.showError(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError('An unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: FocusUtils.unfocus,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Sign Up'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: AppTypography.displaySmall(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to get started',
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  focusNode: _mobileFocusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'Enter your mobile number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameController,
                  focusNode: _businessNameFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    hintText: 'Enter your business name',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => Validators.required(value, 'Business name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _staffSizeController,
                  focusNode: _staffSizeFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Staff Size',
                    hintText: 'Enter number of staff',
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Staff size is required';
                    }
                    final size = int.tryParse(value.trim());
                    if (size == null || size < 0) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  text: 'Sign Up',
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
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
