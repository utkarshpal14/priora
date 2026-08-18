class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInMinutes;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresInMinutes = 15,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'bearer',
      expiresInMinutes: (json['expires_in_minutes'] as int?) ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in_minutes': expiresInMinutes,
    };
  }
}
