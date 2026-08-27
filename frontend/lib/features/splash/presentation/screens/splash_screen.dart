import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/server_warmup_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'Preparing your workspace...';
  double _progress = 0.05;
  bool _isTimedOut = false;
  bool _isWarming = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWarmingSequence();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startWarmingSequence() async {
    setState(() {
      _isWarming = true;
      _isTimedOut = false;
      _statusMessage = 'Preparing your workspace...';
      _progress = 0.05;
    });

    final result = await ServerWarmupService.warmUpServer(
      onProgress: (message, progress) {
        if (mounted) {
          setState(() {
            _statusMessage = message;
            _progress = progress;
          });
        }
      },
      safetyTimeout: const Duration(seconds: 45),
    );

    if (!mounted) return;

    if (result == WarmupResult.ready) {
      await _completeLaunchAndNavigate();
    } else {
      // 45s safety timeout reached without 200 response
      setState(() {
        _isWarming = false;
        _isTimedOut = true;
      });
    }
  }

  Future<void> _completeLaunchAndNavigate() async {
    try {
      await ref.read(authControllerProvider.notifier).initialize();
      final notifService = ref.read(localNotificationServiceProvider);
      await notifService.initialize();
      await notifService.requestPermissions();
    } catch (e) {
      debugPrint('[SplashScreen] Initialization warning: $e');
    }

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated) {
      context.go('/planner');
    } else {
      context.go('/login');
    }
  }

  Future<void> _continueOffline() async {
    await _completeLaunchAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgGradient = isDark
        ? const RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          )
        : const RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.2,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
          );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. Glowing Animated App Logo
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isTimedOut ? 1.0 : _pulseAnimation.value,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: isDark ? 0.25 : 0.15,
                              ),
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _isTimedOut
                                ? Icons.cloud_off_rounded
                                : Icons.rocket_launch_rounded,
                            size: 46,
                            color: _isTimedOut
                                ? const Color(0xFFF59E0B)
                                : theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 2. App Name & Tagline
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.appTagline,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),

                const Spacer(flex: 2),

                // 3. Dynamic Progress State vs Timeout Fallback
                if (_isWarming) ...[
                  // Animated Progress Bar
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 5,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusMessage,
                            key: ValueKey<String>(_statusMessage),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isTimedOut) ...[
                  // Graceful Timeout Recovery Card (UX-005)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          "We're taking a bit longer than expected.",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your workspace is ready. You can retry connecting or continue working offline.",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            height: 1.4,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _continueOffline,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  'Continue Offline',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _startWarmingSequence,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(
                                  'Try Again',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 1),

                // 4. Subtle Version Footer
                Text(
                  'v${AppConstants.appVersion}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
