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
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:frontend/main.dart';

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
  Future<UserModel> register({required String email, required String password, String? fullName}) async {
    return UserModel(
      id: 'test-uuid',
      email: email,
      fullName: fullName ?? 'Test User',
      authProvider: 'email',
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('PrioraApp renders LoginScreen when unauthenticated', (WidgetTester tester) async {
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
        child: const PrioraApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
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
}
