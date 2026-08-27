import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';

enum WarmupResult {
  ready,
  timeout,
  offline,
}

class ServerWarmupService {
  static const Duration defaultTimeout = Duration(seconds: 45);
  static const Duration pingInterval = Duration(seconds: 2);

  /// Performs background warming pings against `/health` with human-centered copy progression.
  static Future<WarmupResult> warmUpServer({
    void Function(String message, double progress)? onProgress,
    Duration safetyTimeout = defaultTimeout,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    final stopwatch = Stopwatch()..start();
    int attempt = 0;

    while (stopwatch.elapsed < safetyTimeout) {
      attempt++;
      final elapsedSeconds = stopwatch.elapsed.inSeconds;

      // Human-friendly progress messaging (UX-005)
      String statusMessage;
      double estimatedProgress;

      if (elapsedSeconds < 5) {
        statusMessage = 'Preparing your workspace...';
        estimatedProgress = (elapsedSeconds / 5.0) * 0.3; // 0% -> 30%
      } else if (elapsedSeconds < 20) {
        statusMessage = 'Syncing your tasks...';
        estimatedProgress = 0.3 + ((elapsedSeconds - 5) / 15.0) * 0.4; // 30% -> 70%
      } else {
        statusMessage = 'Almost ready...';
        estimatedProgress = 0.7 + ((elapsedSeconds - 20) / (safetyTimeout.inSeconds - 20)) * 0.25; // 70% -> 95%
      }

      onProgress?.call(statusMessage, estimatedProgress.clamp(0.05, 0.95));

      try {
        final response = await dio.get(ApiEndpoints.health);
        if (response.statusCode == 200) {
          onProgress?.call('Ready!', 1.0);
          stopwatch.stop();
          return WarmupResult.ready;
        }
      } catch (e) {
        debugPrint('[ServerWarmup] Ping attempt #$attempt (${elapsedSeconds}s): Server still waking up...');
      }

      // Wait interval before next ping, unless timeout has already passed
      final remaining = safetyTimeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) break;

      final waitTime = remaining < pingInterval ? remaining : pingInterval;
      await Future.delayed(waitTime);
    }

    stopwatch.stop();
    return WarmupResult.timeout;
  }
}
