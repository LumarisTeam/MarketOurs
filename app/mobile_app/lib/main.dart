import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations;
import 'package:feedback_sdk/feedback_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';
import 'services/push_notification_service.dart';
import 'services/api_service.dart';
import 'ui/app_responsive.dart';
import 'ui/macos_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.setLocale(PlatformDispatcher.instance.locale.languageCode);

  // 反馈 SDK 初始化（匿名反馈中心）。MarketOurs 无运行时学校概念，固定西建大 slug。
  await FeedbackSdk.init(
    FeedbackConfig(
      baseUrl: 'http://feedbackapi.luckyfishes.site', // TODO: 后端上 TLS 后换 https
      appName: 'lumalis',
      school: 'xauat',
    ),
  );

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

    final brightness =
        themeMode.forcedBrightness ?? MediaQuery.platformBrightnessOf(context);
    final colors = brightness == Brightness.dark
        ? McColors.dark
        : McColors.light;

    return CupertinoApp.router(
      // `build` runs above the app's Localizations widget, so looking up
      // AppLocalizations with this context would always return null during
      // the initial build. Resolve the localized title inside CupertinoApp's
      // localization scope instead.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
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
        return McThemeData.wrap(
          colors: colors,
          locale: appLocale,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(platformBrightness: brightness),
            child: MacosWindow.isMacOS
                ? _MacosWindowLayout(router: router, child: child!)
                : child!,
          ),
        );
      },
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colors.primary,
        scaffoldBackgroundColor: colors.background,
        barBackgroundColor: colors.background,
        textTheme: CupertinoTextThemeData(
          primaryColor: colors.primary,
          textStyle: TextStyle(
            color: colors.foreground,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _MacosWindowLayout extends StatefulWidget {
  const _MacosWindowLayout({required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  State<_MacosWindowLayout> createState() => _MacosWindowLayoutState();
}

class _MacosWindowLayoutState extends State<_MacosWindowLayout> {
  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(covariant _MacosWindowLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
    }
  }

  void _onRouteChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget
        .router
        .routerDelegate
        .currentConfiguration
        .lastOrNull
        ?.matchedLocation;
    final isMainRoute = {
      AppRoutePaths.home,
      AppRoutePaths.teacherComments,
      AppRoutePaths.notifications,
      AppRoutePaths.profile,
    }.contains(path);
    if (isMainRoute && AppResponsive.isDesktop(context)) return widget.child;

    return Column(
      children: [
        GestureDetector(
          key: const ValueKey('macos-titlebar-reservation'),
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => MacosWindow.startDragging(),
          onDoubleTap: MacosWindow.zoom,
          child: ColoredBox(
            color: context.mc.groupedBackground,
            child: const SizedBox(height: 28, width: double.infinity),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
