import 'package:flutter/cupertino.dart';

import '../../ui/app_responsive.dart';
import '../../ui/app_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final padding = AppResponsive.pagePadding(context, narrow: 16, wide: 24);
    final contentMaxWidth = AppResponsive.contentMaxWidth(context);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          title,
          style: TextStyle(
            color: CupertinoDynamicColor.resolve(
              AppColors.foreground,
              context,
            ),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: CupertinoDynamicColor.resolve(
          AppColors.background,
          context,
        ).withValues(alpha: 0.82),
        border: Border(
          bottom: BorderSide(
            color: CupertinoDynamicColor.resolve(
              AppColors.border,
              context,
            ).withValues(alpha: 0.35),
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: ListView(
              padding: padding,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                for (final section in sections)
                  _buildSection(context, section),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '最后更新：$lastUpdated',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoDynamicColor.resolve(
              AppColors.mutedForeground,
              context,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, LegalSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...section.children,
        ],
      ),
    );
  }
}

class LegalSection {
  const LegalSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;
}

Widget legalParagraph(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: _LegalText(text),
  );
}

Widget legalBullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('  •  ', style: TextStyle(fontSize: 14)),
        Expanded(child: _LegalText(text)),
      ],
    ),
  );
}

class _LegalText extends StatelessWidget {
  const _LegalText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: CupertinoDynamicColor.resolve(
          AppColors.mutedForeground,
          context,
        ),
      ),
    );
  }
}
