import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (.env) safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Notice: .env file not found or couldn't be loaded, using defaults.");
  }

  runApp(
    const ProviderScope(
      child: PrioraApp(),
    ),
  );
}

class PrioraApp extends ConsumerStatefulWidget {
  const PrioraApp({super.key});

  @override
  ConsumerState<PrioraApp> createState() => _PrioraAppState();
}

class _PrioraAppState extends ConsumerState<PrioraApp> {
  @override
  void initState() {
    super.initState();
    // Restore user session and initialize native notifications on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(authControllerProvider.notifier).initialize();
      final notifService = ref.read(localNotificationServiceProvider);
      await notifService.initialize();
      await notifService.requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeState.accent),
      darkTheme: AppTheme.darkTheme(themeState.accent),
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}
