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

  Future<({UserModel user, AuthTokens tokens})> register({
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
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final tokens = AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>);
    return (user: user, tokens: tokens);
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

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignored
    }
  }
}
