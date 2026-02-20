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
import '../screens/signup_screen.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Clear focus when screen is mounted to prevent auto-focus on return
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusUtils.unfocus();
        _mobileFocusNode.unfocus();
        _passwordFocusNode.unfocus();
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
        _mobileFocusNode.unfocus();
        _passwordFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    _mobileFocusNode.dispose();
    _passwordFocusNode.dispose();
    FocusUtils.unfocus();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusUtils.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().login(
        mobile: _mobileController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && response.token != null) {
        await StorageService.saveToken(response.token!);
        await StorageService.saveUser(response.user!);

        if (!mounted) return;
        NavigationUtils.pushAndRemoveUntil(const HomeScreen());
        SnackbarUtils.showSuccess('Login successful');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      
      if (e.type == ApiExceptionType.noInternet) {
        NavigationUtils.push(InternetErrorScreen(onRetry: _handleLogin));
      } else if (e.type == ApiExceptionType.serverError) {
        NavigationUtils.push(ServerErrorScreen(onRetry: _handleLogin, message: e.message));
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
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: ResponsiveUtils.responsive(context, mobile: 40, tablet: 60)),
                Icon(
                  Icons.access_time,
                  size: ResponsiveUtils.responsive(context, mobile: 80, tablet: 100),
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: AppTypography.displaySmall(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTypography.bodyMedium(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveUtils.responsive(context, mobile: 40, tablet: 60)),
                TextFormField(
                  controller: _mobileController,
                  focusNode: _mobileFocusNode,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'Enter your mobile number',
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 32),
                LoadingButton(
                  text: 'Login',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTypography.bodyMedium(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        FocusUtils.unfocus();
                        _mobileFocusNode.unfocus();
                        _passwordFocusNode.unfocus();
                        NavigationUtils.push(const SignupScreen());
                      },
                      child: const Text('Sign Up'),
                    ),
                  ],
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
