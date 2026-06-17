import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/push_notification_service.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
