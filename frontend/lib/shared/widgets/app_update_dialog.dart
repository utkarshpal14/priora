import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/app_version_model.dart';
import '../../core/services/app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppVersionModel versionModel;
  final String currentVersion;

  const AppUpdateDialog({
    super.key,
    required this.versionModel,
    required this.currentVersion,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> with WidgetsBindingObserver {
  bool _isDownloading = false;
  bool _isPermissionRequired = false;
  String? _downloadedApkPath;
  double _progress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from Android Settings (ACTION_MANAGE_UNKNOWN_APP_SOURCES)
    if (state == AppLifecycleState.resumed && _isPermissionRequired && _downloadedApkPath != null) {
      _checkPermissionAndInstall();
    }
  }

  Future<void> _checkPermissionAndInstall() async {
    final hasPermission = await AppUpdateService.canRequestPackageInstalls();
    if (hasPermission && _downloadedApkPath != null && mounted) {
      setState(() {
        _isPermissionRequired = false;
        _statusMessage = 'Launching installer...';
      });
      final res = await AppUpdateService.installDownloadedApk(_downloadedApkPath!);
      if (res == 'SUCCESS' && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _isPermissionRequired = false;
      _downloadedApkPath = null;
      _progress = 0.0;
      _statusMessage = 'Connecting...';
      _errorMessage = null;
      _cancelToken = CancelToken();
    });

    AppUpdateService.downloadAndInstallApk(
      downloadUrl: widget.versionModel.apkDownloadUrl,
      cancelToken: _cancelToken,
      onProgress: (progress, label) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _statusMessage = label;
          });
        }
      },
      onPermissionRequired: (apkPath) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isPermissionRequired = true;
            _downloadedApkPath = apkPath;
            _statusMessage = 'Permission needed to install';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isPermissionRequired = false;
            _errorMessage = error;
          });
        }
      },
    );
  }

  Future<void> _installDownloadedApk() async {
    if (_downloadedApkPath == null) {
      _startDownload();
      return;
    }

    final res = await AppUpdateService.installDownloadedApk(_downloadedApkPath!);
    if (res == 'SUCCESS' && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (res == 'PERMISSION_REQUIRED') {
      if (mounted) {
        setState(() {
          _isPermissionRequired = true;
        });
      }
    } else {
      // Fallback to external download if direct file installation fails
      AppUpdateService.launchDownload(widget.versionModel.apkDownloadUrl);
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _isPermissionRequired = false;
      _progress = 0.0;
      _statusMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = theme.colorScheme.primary;

    return PopScope(
      canPop: !widget.versionModel.forceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isDownloading
                      ? Icons.downloading_rounded
                      : _isPermissionRequired
                          ? Icons.security_rounded
                          : Icons.rocket_launch_rounded,
                  size: 32,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                _isDownloading
                    ? 'Downloading Update...'
                    : _isPermissionRequired
                        ? 'Permission Required'
                        : 'Update Available!',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(height: 8),

              // Version Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0EDE6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E0D8),
                  ),
                ),
                child: Text(
                  'v${widget.currentVersion}  →  v${widget.versionModel.latestVersion}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Downloading Progress State
              if (_isDownloading) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _statusMessage,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelDownload,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: Text(
                      'Cancel Download',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ] else if (_isPermissionRequired) ...[
                // Unknown App Sources Permission Guidance State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'APK downloaded successfully! Android requires permission to install updates directly.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Enable "Allow from this source" in Settings\n2. Return here and tap "Install APK"',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (!widget.versionModel.forceUpdate) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            'Later',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _installDownloadedApk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Install APK',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Error message if previous download failed
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFFCA5A5) : Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (widget.versionModel.releaseNotes.isNotEmpty) ...[
                  // Release Notes / Highlights
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 130),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFF9F7F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECE7DF),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.versionModel.releaseNotes,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action Buttons
                Row(
                  children: [
                    if (!widget.versionModel.forceUpdate) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Text(
                            'Later',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _startDownload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _errorMessage != null ? 'Try Again' : 'Update Now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
