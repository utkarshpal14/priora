import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_endpoints.dart';
import '../models/app_version_model.dart';
import '../../shared/widgets/app_update_dialog.dart';

class AppUpdateService {
  /// The current hardcoded client build version.
  /// Increment this when publishing new releases.
  static const String currentInstalledVersion = '1.1.0';

  static const MethodChannel _systemChannel = MethodChannel('com.example.frontend/system_settings');

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  /// Compares two semantic version strings (e.g., "1.0.0" and "1.1.0").
  /// Returns `true` if [latestVersion] is strictly newer than [installedVersion].
  static bool isUpdateAvailable(String installedVersion, String latestVersion) {
    try {
      final installedParts = _parseVersion(installedVersion);
      final latestParts = _parseVersion(latestVersion);

      for (int i = 0; i < 3; i++) {
        final installed = i < installedParts.length ? installedParts[i] : 0;
        final latest = i < latestParts.length ? latestParts[i] : 0;

        if (latest > installed) {
          return true;
        } else if (latest < installed) {
          return false;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parseVersion(String version) {
    final clean = version.trim().replaceAll(RegExp(r'[^0-9.]'), '');
    return clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  /// Silently queries the backend for the latest public app release version.
  static Future<AppVersionModel?> fetchLatestVersion() async {
    try {
      final response = await _dio.get(ApiEndpoints.appVersion);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return AppVersionModel.fromJson(data);
        }
      }
    } catch (e) {
      // Fail silently if backend is offline or warming up
      debugPrint('AppUpdateService: version check silent skip ($e)');
    }
    return null;
  }

  /// Automatically checks for updates and displays the update dialog if available.
  static Future<void> checkForUpdates(BuildContext context) async {
    final versionModel = await fetchLatestVersion();
    if (versionModel == null || !context.mounted) return;

    if (isUpdateAvailable(currentInstalledVersion, versionModel.latestVersion)) {
      showDialog<void>(
        context: context,
        barrierDismissible: !versionModel.forceUpdate,
        builder: (dialogContext) => AppUpdateDialog(
          versionModel: versionModel,
          currentVersion: currentInstalledVersion,
        ),
      );
    }
  }

  /// Checks whether Android allows installing unknown apps.
  static Future<bool> canRequestPackageInstalls() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final res = await _systemChannel.invokeMethod<bool>('canRequestPackageInstalls');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Directly invokes the native Android package installer on an existing downloaded APK file.
  /// Returns 'SUCCESS', 'PERMISSION_REQUIRED', or 'ERROR'.
  static Future<String> installDownloadedApk(String apkPath) async {
    if (kIsWeb || !Platform.isAndroid) return 'UNSUPPORTED';
    try {
      final res = await _systemChannel.invokeMethod<String>('installApk', {'filePath': apkPath});
      return res ?? 'ERROR';
    } catch (e) {
      debugPrint('AppUpdateService: Error invoking native installer: $e');
      return 'ERROR';
    }
  }

  /// Downloads the APK directly inside the app with a real-time progress callback,
  /// and automatically triggers the native Android package installer.
  static Future<void> downloadAndInstallApk({
    required String downloadUrl,
    required void Function(double progress, String progressLabel) onProgress,
    required void Function(String errorMessage) onError,
    required void Function(String apkPath) onPermissionRequired,
    CancelToken? cancelToken,
  }) async {
    if (downloadUrl.isEmpty) {
      onError('Download URL is empty.');
      return;
    }

    // On Web or non-Android, launch external download directly
    if (kIsWeb || !Platform.isAndroid) {
      await launchDownload(downloadUrl);
      return;
    }

    try {
      final cacheDir = await getTemporaryDirectory();
      final apkPath = '${cacheDir.path}/priora-update.apk';

      // Delete existing stale update file if present
      final existingFile = File(apkPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }

      onProgress(0.0, 'Starting download...');

      await _dio.download(
        downloadUrl,
        apkPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total).clamp(0.0, 1.0);
            final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
            onProgress(progress, '$mbReceived MB / $mbTotal MB');
          } else {
            final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
            onProgress(0.5, '$mbReceived MB downloaded');
          }
        },
      );

      onProgress(1.0, 'Launching installer...');

      // Invoke native Android installer Intent with FileProvider
      final installResult = await installDownloadedApk(apkPath);
      if (installResult == 'PERMISSION_REQUIRED') {
        onPermissionRequired(apkPath);
      } else if (installResult != 'SUCCESS') {
        // Fallback to external download if native package installer invocation fails
        await launchDownload(downloadUrl);
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('AppUpdateService: download cancelled by user.');
        return;
      }
      debugPrint('AppUpdateService: In-app download error: $e');
      onError('Download failed. Tap to open in browser.');
    }
  }

  /// Launches external APK download URL in browser / package installer.
  static Future<void> launchDownload(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('AppUpdateService: could not launch download URL ($e)');
    }
  }
}

