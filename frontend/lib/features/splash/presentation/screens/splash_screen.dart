import 'dart:async';
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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _statusMessage = 'Preparing your workspace...';
  double _progress = 0.05;
  bool _isTimedOut = false;
  bool _isWarming = true;

  int _featureIndex = 0;
  Timer? _featureTimer;

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.view_timeline_rounded,
      'title': 'Hourly Timeline Planner',
      'desc': 'Intelligent time-blocking & daily scheduling',
    },
    {
      'icon': Icons.track_changes_rounded,
      'title': 'Priority Focus Matrix',
      'desc': 'Smart urgency alerts & deadline tracking',
    },
    {
      'icon': Icons.notifications_active_rounded,
      'title': 'Custom Sound Chimes',
      'desc': 'Exact alarm reminders with distinct audio',
    },
    {
      'icon': Icons.auto_graph_rounded,
      'title': 'Goals & Daily Review',
      'desc': 'Reflect, reschedule & track your progress',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Pulse & glow animation for the app badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Entry fade & slide animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Rotate feature pills every 2.8s
    _featureTimer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (mounted && _isWarming) {
        setState(() {
          _featureIndex = (_featureIndex + 1) % _features.length;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWarmingSequence();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _featureTimer?.cancel();
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

    // Palette tailored to Priora brand identity
    final bgColors = isDark
        ? [
            const Color(0xFF0F172A),
            const Color(0xFF0A0E1A),
            const Color(0xFF050811),
          ]
        : [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
            const Color(0xFF090D18),
          ];

    final currentFeature = _features[_featureIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF090D18),
      body: Stack(
        children: [
          // 1. Deep Midnight Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
          ),

          // 2. Ambient Gold & Cobalt Light Orbs
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Gold light orb top
                  Positioned(
                    top: -60,
                    left: MediaQuery.of(context).size.width * 0.2,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE5A93C)
                            .withValues(alpha: _glowAnimation.value * 0.22),
                      ),
                    ),
                  ),
                  // Royal blue light orb center
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.28,
                    right: -40,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B82F6)
                            .withValues(alpha: _glowAnimation.value * 0.24),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 3. Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // A. Official Brand App Icon with Glowing Halo
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isTimedOut ? 1.0 : _pulseAnimation.value,
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE5A93C).withValues(
                                      alpha: _glowAnimation.value * 0.35,
                                    ),
                                    blurRadius: 36,
                                    spreadRadius: 4,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(
                                      alpha: _glowAnimation.value * 0.3,
                                    ),
                                    blurRadius: 48,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFF0F172A),
                                      child: const Center(
                                        child: Icon(
                                          Icons.rocket_launch_rounded,
                                          size: 52,
                                          color: Color(0xFFE5A93C),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // B. Brand Title with Gold Accent Dot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: GoogleFonts.outfit(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 4, top: 12),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE5A93C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // C. Brand Tagline
                      Text(
                        'PRIORITIZE • PLAN • PROGRESS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: const Color(0xFFF3D079),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // D. Dynamic Feature Highlights Showcase (Communicates what app does!)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            key: ValueKey<int>(_featureIndex),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A93C)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5A93C)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Icon(
                                  currentFeature['icon'] as IconData,
                                  size: 22,
                                  color: const Color(0xFFF3D079),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currentFeature['title'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentFeature['desc'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      // E. Warming Progress Bar vs Recovery Timeout State
                      if (_isWarming) ...[
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              // Glowing Gradient Progress Bar
                              Container(
                                width: double.infinity,
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: constraints.maxWidth * _progress,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(999),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFE5A93C),
                                              Color(0xFF38BDF8),
                                              Color(0xFF3B82F6),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF38BDF8)
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Human-Friendly Status Message
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _statusMessage,
                                  key: ValueKey<String>(_statusMessage),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_isTimedOut) ...[
                        // Graceful Timeout Recovery Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D33),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE5A93C)
                                  .withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_queue_rounded,
                                    size: 18,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Server is taking longer to respond",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Your local workspace is ready. You can continue offline or retry connecting.",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: const Color(0xFF94A3B8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _continueOffline,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Text(
                                        'Continue Offline',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _startWarmingSequence,
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 16),
                                      label: Text(
                                        'Try Again',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE5A93C),
                                        foregroundColor:
                                            const Color(0xFF0F172A),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
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

                      // F. Subtle Brand Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: const Color(0xFFE5A93C).withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Smart Productivity Platform • v${AppConstants.appVersion}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
