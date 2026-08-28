import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';
import '../../domain/user_model.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final GoogleSignIn _googleSignIn;

  AuthController(
    this._repository, {
    GoogleSignIn? googleSignIn,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId: (dotenv.isInitialized &&
                      (dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID')?.isNotEmpty ?? false))
                  ? dotenv.maybeGet('GOOGLE_WEB_CLIENT_ID')
                  : null,
            ),
        super(AuthState.initial());

  /// Startup session restoration flow
  Future<void> initialize() async {
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        // If server was unreachable or warming, check if tokens exist in secure storage
        final hasSession = await _repository.hasStoredSession();
        if (hasSession) {
          state = AuthState.authenticated(
            UserModel(
              id: 'offline_user',
              email: 'user@priora.local',
              fullName: 'Priora User',
              isEmailVerified: true,
            ),
          );
        } else {
          state = AuthState.unauthenticated();
        }
      }
    } catch (e) {
      final hasSession = await _repository.hasStoredSession();
      if (hasSession) {
        state = AuthState.authenticated(
          UserModel(
            id: 'offline_user',
            email: 'user@priora.local',
            fullName: 'Priora User',
            isEmailVerified: true,
          ),
        );
      } else {
        state = AuthState.unauthenticated();
      }
    }
  }

  /// Email & password sign in
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, fallback: 'Invalid email or password.');
      state = AuthState.error(message);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Email & password account registration
  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthState.authenticated(user);
      return true;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, fallback: 'Failed to create account.');
      state = AuthState.error(message);
      return false;
    } catch (e) {
      state = AuthState.error('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Google Sign-In flow
  Future<bool> loginWithGoogle() async {
    state = AuthState.authenticating();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled sign in
        state = AuthState.unauthenticated();
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        state = AuthState.error('Could not retrieve Google ID Token.');
        return false;
      }

      final user = await _repository.loginWithGoogle(idToken);
      state = AuthState.authenticated(user);
      return true;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e, fallback: 'Google sign-in failed.');
      state = AuthState.error(message);
      return false;
    } catch (e) {
      state = AuthState.error('Google sign-in failed: ${e.toString()}');
      return false;
    }
  }

  /// Sign out session
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _repository.logout();
    state = AuthState.unauthenticated();
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['detail'] is String) {
        return data['detail'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return fallback;
  }
}
