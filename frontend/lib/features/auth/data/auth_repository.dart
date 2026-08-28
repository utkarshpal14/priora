import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_model.dart';
import 'auth_api.dart';
import 'auth_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApi = ref.watch(authApiProvider);
  final authStorage = ref.watch(authStorageProvider);
  return AuthRepository(authApi, authStorage);
});

class AuthRepository {
  final AuthApi _authApi;
  final AuthStorage _authStorage;

  AuthRepository(this._authApi, this._authStorage);

  Future<({String email, bool isEmailVerified, String message})> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _authApi.register(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<UserModel> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final result = await _authApi.verifyOtp(
      email: email,
      otpCode: otpCode,
    );
    await _authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    return result.user;
  }

  Future<({String email, int cooldownSeconds, String message})> resendOtp({
    required String email,
  }) async {
    return await _authApi.resendOtp(
      email: email,
    );
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final result = await _authApi.login(
      email: email,
      password: password,
    );
    await _authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    return result.user;
  }

  Future<UserModel> loginWithGoogle(String idToken) async {
    final result = await _authApi.loginWithGoogle(idToken: idToken);
    await _authStorage.saveTokens(
      accessToken: result.tokens.accessToken,
      refreshToken: result.tokens.refreshToken,
    );
    return result.user;
  }

  Future<void> logout() async {
    await _authApi.logout();
    await _authStorage.clearTokens();
  }

  Future<bool> hasStoredSession() async {
    final accessToken = await _authStorage.getAccessToken();
    final refreshToken = await _authStorage.getRefreshToken();
    return (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);
  }

  Future<UserModel?> restoreSession() async {
    final accessToken = await _authStorage.getAccessToken();
    final refreshToken = await _authStorage.getRefreshToken();

    if (accessToken == null && refreshToken == null) {
      return null;
    }

    try {
      // 1. Attempt fetching user with current access token
      return await _authApi.getCurrentUser();
    } on DioException catch (e) {
      // 2. If access token expired (401) and we have a refresh token, try refreshing
      if (e.response?.statusCode == 401 && refreshToken != null) {
        try {
          final newTokens = await _authApi.refreshToken(refreshToken);
          await _authStorage.saveTokens(
            accessToken: newTokens.accessToken,
            refreshToken: newTokens.refreshToken,
          );
          return await _authApi.getCurrentUser();
        } on DioException catch (refreshErr) {
          // Only clear tokens if the refresh token was explicitly rejected (401/403)
          if (refreshErr.response?.statusCode == 401 || refreshErr.response?.statusCode == 403) {
            await _authStorage.clearTokens();
          }
          return null;
        } catch (_) {
          return null;
        }
      }

      // If server explicitly rejected the token as invalid (401/403) and no refresh possible
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await _authStorage.clearTokens();
        return null;
      }

      // For network connection errors, timeouts, or 500s (e.g. server warming / offline),
      // DO NOT clear stored tokens. Preserve session immortality (Rule 9).
      return null;
    } catch (_) {
      return null;
    }
  }
}
