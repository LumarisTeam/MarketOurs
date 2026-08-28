import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:feedback_sdk/feedback_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/push_notification_service.dart';
import 'services/api_service.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setLocale(PlatformDispatcher.instance.locale.languageCode);

  // 反馈 SDK 初始化（匿名反馈中心）。MarketOurs 无运行时学校概念，固定西建大 slug。
  await FeedbackSdk.init(FeedbackConfig(
    baseUrl: 'http://feedbackapi.luckyfishes.site', // TODO: 后端上 TLS 后换 https
    appName: 'lumalis',
    school: 'xauat',
  ));

  runApp(const ProviderScope(child: MarketOursApp()));
}

class MarketOursApp extends ConsumerWidget {
  const MarketOursApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final appLocale = ref.watch(localeNotifierProvider);

    ref.listen(appRouterProvider, (_, next) {
      PushNotificationService.instance.initialize(router: next);
    });
    PushNotificationService.instance.initialize(router: router);

    return CupertinoApp.router(
      title: 'MarketOurs',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: appLocale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
