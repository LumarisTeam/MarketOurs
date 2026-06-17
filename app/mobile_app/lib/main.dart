import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/app_logger.dart';
import 'services/push_notification_service.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseIfConfigured();
  runApp(const ProviderScope(child: MarketOursApp()));
}

class MarketOursApp extends ConsumerWidget {
  const MarketOursApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    ref.listen(appRouterProvider, (_, next) {
      PushNotificationService.instance.initialize(router: next);
    });
    PushNotificationService.instance.initialize(router: router);

    return CupertinoApp.router(
      title: '光汇',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        final forcedBrightness = themeMode.forcedBrightness;
        if (forcedBrightness != null) {
          child = MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(platformBrightness: forcedBrightness),
            child: child!,
          );
        }
        return child!;
      },
      theme: CupertinoThemeData(
        brightness:
            themeMode.forcedBrightness ??
            MediaQuery.platformBrightnessOf(context),
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        barBackgroundColor: AppColors.background,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: AppColors.foreground,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeFirebaseIfConfigured() async {
  if (kIsWeb || !DefaultFirebaseOptions.isConfigured) {
    AppLogger.warn(
      'Bootstrap',
      'Firebase is not configured. Push notifications will stay disabled.',
    );
    return;
  }

  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      AppLogger.warn(
        'Bootstrap',
        'Firebase options missing for current platform. Push disabled.',
      );
      return;
    }
    await Firebase.initializeApp(options: options);
  } catch (error, stackTrace) {
    AppLogger.error(
      'Bootstrap',
      'Firebase initialization failed. Push notifications are disabled.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
