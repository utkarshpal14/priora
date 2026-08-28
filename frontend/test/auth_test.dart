import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_storage.dart';
import 'package:frontend/features/auth/domain/auth_state.dart';
import 'package:frontend/features/auth/domain/user_model.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:frontend/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:frontend/features/auth/presentation/screens/verify_email_screen.dart';

class FakeAuthStorage extends AuthStorage {
  String? _access;
  String? _refresh;

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(AuthApi(Dio()), FakeAuthStorage());

  @override
  Future<UserModel?> restoreSession() async => null;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    return UserModel(
      id: 'test-uuid',
      email: email,
      fullName: 'Test User',
      authProvider: 'email',
    );
  }

  @override
  Future<({String email, bool isEmailVerified, String message})> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return (
      email: email,
      isEmailVerified: false,
      message: 'Verification code sent.',
    );
  }

  @override
  Future<UserModel> verifyOtp({required String email, required String otpCode}) async {
    return UserModel(
      id: 'test-uuid',
      email: email,
      fullName: 'Test User',
      authProvider: 'email',
      isEmailVerified: true,
    );
  }

  @override
  Future<({String email, int cooldownSeconds, String message})> resendOtp({required String email}) async {
    return (
      email: email,
      cooldownSeconds: 60,
      message: 'New code sent.',
    );
  }

  @override
  Future<String> forgotPassword({required String email}) async {
    return 'If an account exists, a reset code was sent.';
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    return 'Your password has been successfully reset.';
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('LoginScreen renders properly when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          authControllerProvider.overrideWith((ref) {
            final repo = ref.watch(authRepositoryProvider);
            final controller = AuthController(repo);
            controller.state = AuthState.unauthenticated();
            return controller;
          }),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });

  testWidgets('LoginScreen displays validation error when email is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // Tap Sign In button
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders properly and validates fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full Name (Optional)'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    // Ensure button is visible before tapping
    await tester.ensureVisible(find.text('Create Account'));
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
    expect(find.text('Please enter a password.'), findsOneWidget);
  });

  testWidgets('VerifyEmailScreen renders 6 OTP boxes and resend countdown timer', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: VerifyEmailScreen(email: 'tester@priora.app'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('tester@priora.app'), findsOneWidget);
    expect(find.text('Verify & Activate Account'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));

    // Dispose widget to cancel periodic timer cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('ForgotPasswordScreen renders properly and validates email field', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Send Recovery Code'), findsOneWidget);

    // Tap Send Recovery Code with empty email
    await tester.tap(find.text('Send Recovery Code'));
    await tester.pump();

    expect(find.text('Please enter your email address.'), findsOneWidget);
  });

  testWidgets('ResetPasswordScreen renders 6 OTP boxes, new password fields, and resend timer', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(
          home: ResetPasswordScreen(email: 'reset_hero@priora.app'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create New Password'), findsOneWidget);
    expect(find.textContaining('reset_hero@priora.app'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(8)); // 6 OTP boxes + 2 password fields

    // Cleanly cancel timer
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
