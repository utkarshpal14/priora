import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authControllerProvider.notifier).register(
            email: _emailController.text,
            password: _passwordController.text,
            fullName: _fullNameController.text.isNotEmpty ? _fullNameController.text : null,
          );
    }
  }

  void _handleGoogleLogin() {
    ref.read(authControllerProvider.notifier).loginWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Header
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.secondary : AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'P',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Start planning with ${AppConstants.appName}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Google Sign-In Button
                    GoogleSignInButton(
                      onPressed: _handleGoogleLogin,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.border,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'or register with email',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF64748B) : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.border,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Error Feedback Banner
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Full Name Field
                    AuthTextField(
                      controller: _fullNameController,
                      label: 'Full Name (Optional)',
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Min 8 characters',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password.';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Create Account Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? theme.colorScheme.secondary : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Switch to Sign In
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign in',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? theme.colorScheme.secondary : AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
