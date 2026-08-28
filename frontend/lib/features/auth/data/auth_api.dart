import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_tokens.dart';
import '../domain/user_model.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApi(dio);
});

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<({String email, bool isEmailVerified, String message})> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName?.trim(),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return (
      email: data['email'] as String,
      isEmailVerified: data['is_email_verified'] as bool? ?? false,
      message: data['message'] as String? ?? 'Verification code sent.',
    );
  }

  Future<({UserModel user, AuthTokens tokens})> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.verifyOtp,
      data: {
        'email': email.trim(),
        'otp_code': otpCode.trim(),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    return (user: user, tokens: tokens);
  }

  Future<({String email, int cooldownSeconds, String message})> resendOtp({
    required String email,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.resendOtp,
      data: {
        'email': email.trim(),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return (
      email: data['email'] as String,
      cooldownSeconds: data['cooldown_seconds'] as int? ?? 60,
      message: data['message'] as String? ?? 'A new verification code has been sent.',
    );
  }

  Future<({UserModel user, AuthTokens tokens})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    return (user: user, tokens: tokens);
  }

  Future<({UserModel user, AuthTokens tokens})> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.google,
      data: {
        'id_token': idToken,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    return (user: user, tokens: tokens);
  }

  Future<AuthTokens> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiEndpoints.refresh,
      data: {
        'refresh_token': refreshToken,
      },
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return AuthTokens.fromJson(data);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.userProfile);
    final data = response.data['data'] as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {
        'email': email.trim(),
      },
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    return data?['message'] as String? ?? 'If an account exists, a reset code was sent.';
  }

  Future<String> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'email': email.trim(),
        'otp_code': otpCode.trim(),
        'new_password': newPassword,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    return data?['message'] as String? ?? 'Your password has been successfully reset.';
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignored
    }
  }
}
