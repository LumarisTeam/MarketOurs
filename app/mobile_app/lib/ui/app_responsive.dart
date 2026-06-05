import 'package:flutter/cupertino.dart';

abstract final class AppBreakpoints {
  static const tablet = 768.0;
  static const desktop = 1100.0;
}

abstract final class AppResponsive {
  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
  }

  static bool isWideTwoPane(BuildContext context) {
    return isDesktop(context);
  }

  static double contentMaxWidth(BuildContext context, {double? fallback}) {
    if (isDesktop(context)) {
      return fallback ?? 1180;
    }
    if (isTablet(context)) {
      return fallback ?? 720;
    }
    return fallback ?? double.infinity;
  }

  static double formMaxWidth(BuildContext context) {
    return isDesktop(context) ? 980 : contentMaxWidth(context, fallback: 720);
  }

  static double readableMaxWidth(BuildContext context, {double? fallback}) {
    if (isDesktop(context)) {
      return fallback ?? 920;
    }
    if (isTablet(context)) {
      return fallback ?? 720;
    }
    return fallback ?? double.infinity;
  }

  static double sheetMaxWidth(BuildContext context) {
    return isPhone(context) ? double.infinity : 560;
  }

  static double sidePaneWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1280) return 360;
    return 320;
  }

  static double twoPaneGap(BuildContext context) {
    return isDesktop(context) ? 24 : 16;
  }

  static int listColumnCount(BuildContext context) {
    return isDesktop(context) ? 2 : 1;
  }

  static double horizontalPadding(
    BuildContext context, {
    double narrow = 16,
    double tablet = 24,
    double desktop = 28,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return narrow;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double narrow = 16,
    double wide = 24,
  }) {
    final horizontal = horizontalPadding(
      context,
      narrow: narrow,
      tablet: wide,
      desktop: wide,
    );
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: isTablet(context) ? wide : narrow,
    );
  }

  static EdgeInsets sliverPagePadding(
    BuildContext context, {
    double top = 12,
    double bottom = 24,
    double narrow = 16,
    double wide = 24,
  }) {
    final horizontal = horizontalPadding(
      context,
      narrow: narrow,
      tablet: wide,
      desktop: wide,
    );
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }
}

class AppResponsiveCenter extends StatelessWidget {
  const AppResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final contentPadding =
        padding ?? AppResponsive.pagePadding(context, narrow: 16, wide: 24);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppResponsive.contentMaxWidth(context),
        ),
        child: Padding(padding: contentPadding, child: child),
      ),
    );
  }
}

class AppResponsiveSliverPadding extends StatelessWidget {
  const AppResponsiveSliverPadding({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding ?? AppResponsive.sliverPagePadding(context),
      sliver: SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? AppResponsive.contentMaxWidth(context),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppTwoPane extends StatelessWidget {
  const AppTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.secondaryWidth,
    this.gap,
    this.secondaryFirstOnWide = false,
    this.stackGap = 16,
  });

  final Widget primary;
  final Widget secondary;
  final double? secondaryWidth;
  final double? gap;
  final bool secondaryFirstOnWide;
  final double stackGap;

  @override
  Widget build(BuildContext context) {
    if (!AppResponsive.isWideTwoPane(context)) {
      final children = secondaryFirstOnWide
          ? <Widget>[
              secondary,
              SizedBox(height: stackGap),
              primary,
            ]
          : <Widget>[
              primary,
              SizedBox(height: stackGap),
              secondary,
            ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    final side = SizedBox(
      width: secondaryWidth ?? AppResponsive.sidePaneWidth(context),
      child: secondary,
    );
    final main = Expanded(child: primary);
    final children = secondaryFirstOnWide
        ? <Widget>[
            side,
            SizedBox(width: gap ?? AppResponsive.twoPaneGap(context)),
            main,
          ]
        : <Widget>[
            main,
            SizedBox(width: gap ?? AppResponsive.twoPaneGap(context)),
            side,
          ];

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}
