import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
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
    // Restore user session on app startup (Document 11 & User Requirement 7)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
