import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'app_theme.dart';

abstract final class AppFeedback {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static Future<void> showMessage(
    BuildContext context, {
    required String message,
    String title = '提示',
  }) {
    return showInfo(context, message: message);
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    return _showToast(
      context,
      message: message,
      title: title,
      icon: CupertinoIcons.info_circle_fill,
      tint: AppColors.primary,
    );
  }

  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    return _showToast(
      context,
      message: message,
      title: title,
      icon: CupertinoIcons.check_mark_circled_solid,
      tint: const Color(0xFF34C759),
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String message,
    String? title,
  }) {
    return _showToast(
      context,
      message: message,
      title: title,
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      tint: AppColors.destructive,
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String message,
    String title = '确认',
    String cancelText = '取消',
    String confirmText = '确定',
    bool destructive = false,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _FeedbackDialog(
        title: title,
        message: message,
        actions: [
          _FeedbackAction(
            label: cancelText,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          _FeedbackAction(
            label: confirmText,
            onPressed: () => Navigator.of(context).pop(true),
            isPrimary: !destructive,
            isDestructive: destructive,
          ),
        ],
      ),
    );
  }

  static Future<void> _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color tint,
    String? title,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return showCupertinoDialog<void>(
        context: context,
        builder: (context) => _FeedbackDialog(
          title: title ?? '提示',
          message: message,
          actions: [
            _FeedbackAction(
              label: '确定',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: true,
            ),
          ],
        ),
      );
    }

    _dismissTimer?.cancel();
    _activeEntry?.remove();

    final entry = OverlayEntry(
      builder: (overlayContext) => _FeedbackToast(
        message: message,
        title: title,
        icon: icon,
        tint: tint,
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (_activeEntry == entry) {
        entry.remove();
        _activeEntry = null;
      }
    });
  }
}

class _FeedbackDialog extends StatelessWidget {
  const _FeedbackDialog({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CupertinoPopupSurface(
      isSurfacePainted: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                AppColors.background,
                context,
              ).withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: AppShadows.none,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.sectionTitle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTextStyles.muted(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (final (index, action) in actions.indexed) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(child: action),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackToast extends StatelessWidget {
  const _FeedbackToast({
    required this.message,
    required this.icon,
    required this.tint,
    this.title,
  });

  final String message;
  final String? title;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final resolvedTint = CupertinoDynamicColor.resolve(tint, context);

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      AppColors.card,
                      context,
                    ).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(
                      color: resolvedTint.withValues(alpha: 0.16),
                    ),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: resolvedTint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Icon(icon, size: 18, color: resolvedTint),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null && title!.trim().isNotEmpty) ...[
                              Text(
                                title!,
                                style: AppTextStyles.label(context).copyWith(
                                  color: resolvedTint,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              message,
                              style: AppTextStyles.body(
                                context,
                              ).copyWith(fontSize: 14, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackAction extends StatelessWidget {
  const _FeedbackAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? AppColors.destructive.withValues(alpha: 0.12)
        : isPrimary
        ? AppColors.primary
        : AppColors.secondary;
    final foregroundColor = isDestructive
        ? AppColors.destructive
        : isPrimary
        ? AppColors.primaryForeground
        : AppColors.foreground;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      color: CupertinoDynamicColor.resolve(backgroundColor, context),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoDynamicColor.resolve(foregroundColor, context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
