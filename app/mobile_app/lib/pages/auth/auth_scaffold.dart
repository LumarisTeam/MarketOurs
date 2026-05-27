import 'package:flutter/cupertino.dart';

import '../../ui/app_responsive.dart';
import '../../ui/app_theme.dart';
import '../../ui/app_widgets.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppResponsive.pagePadding(context, narrow: 20, wide: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.hero(context)),
                      ],
                    ),
                  ),
                  AppGlassCard(
                    padding: const EdgeInsets.all(24),
                    radius: AppRadii.lg,
                    child: child,
                  ),
                  if (footer != null) ...[const SizedBox(height: 14), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
