import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authStorageProvider = Provider<AuthStorage>((ref) {
  return AuthStorage();
});

class AuthStorage {
  static const String _accessTokenKey = 'priora_access_token';
  static const String _refreshTokenKey = 'priora_refresh_token';

  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryFallback = {};

  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              webOptions: WebOptions(dbName: 'priora_db'),
            );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _memoryFallback[_accessTokenKey] = accessToken;
    _memoryFallback[_refreshTokenKey] = refreshToken;
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      // Fallback kept in memory if secure storage fails in test environment
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey) ?? _memoryFallback[_accessTokenKey];
    } catch (_) {
      return _memoryFallback[_accessTokenKey];
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey) ?? _memoryFallback[_refreshTokenKey];
    } catch (_) {
      return _memoryFallback[_refreshTokenKey];
    }
  }

  Future<void> clearTokens() async {
    _memoryFallback.remove(_accessTokenKey);
    _memoryFallback.remove(_refreshTokenKey);
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {
      // Ignored
    }
  }
}
