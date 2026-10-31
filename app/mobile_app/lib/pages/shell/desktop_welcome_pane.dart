import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:luamris_ui/luamris_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/desktop_detail_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../router/app_router.dart';

/// Right-hand placeholder column of the desktop shell.
///
/// Shown when no post is selected: brand block, quick branch shortcuts and the
/// hot-list top 5. Selecting a hot post opens it in the same column.
class DesktopWelcomePane extends ConsumerWidget {
  const DesktopWelcomePane({super.key, required this.onSelectBranch});

  /// Switches the main shell to the given branch index.
  final ValueChanged<int> onSelectBranch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider).asData?.value;
    final isAuthenticated = authState?.status == AuthStatus.authenticated;
    final hotPosts =
        ref.watch(hotFeedProvider).asData?.value.posts ?? const <PostDto>[];

    return CupertinoPageScaffold(
      key: const ValueKey('desktop-welcome-pane'),
      backgroundColor: context.mc.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Brand(),
                const SizedBox(height: 28),
                _SectionTitle(text: l10n.shellQuickActions),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _QuickAction(
                      icon: CupertinoIcons.house_fill,
                      label: l10n.tabHome,
                      onTap: () => onSelectBranch(0),
                    ),
                    _QuickAction(
                      icon: CupertinoIcons.book_fill,
                      label: l10n.tabTeacherComments,
                      onTap: () => onSelectBranch(1),
                    ),
                    _QuickAction(
                      icon: CupertinoIcons.bell_fill,
                      label: l10n.tabNotifications,
                      onTap: () => onSelectBranch(2),
                    ),
                    _QuickAction(
                      icon: CupertinoIcons.person_fill,
                      label: l10n.tabProfile,
                      onTap: () => onSelectBranch(3),
                    ),
                    _QuickAction(
                      icon: CupertinoIcons.plus_circle_fill,
                      label: l10n.postCreate,
                      onTap: () {
                        if (isAuthenticated) {
                          context.push(AppRoutePaths.createPost);
                        } else {
                          context.go(AppRoutePaths.login);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  text: l10n.shellHotTop5,
                  icon: CupertinoIcons.flame,
                ),
                const SizedBox(height: 12),
                if (hotPosts.isEmpty)
                  Text(
                    l10n.hotListEmpty,
                    style: context.mc.textMuted,
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: context.mc.secondary,
                      borderRadius: BorderRadius.circular(McRadii.lg),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        for (final entry in hotPosts.take(5).indexed)
                          _HotRankRow(
                            post: entry.$2,
                            rank: entry.$1 + 1,
                            onTap: () => ref
                                .read(desktopDetailProvider.notifier)
                                .select(entry.$2.id),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  l10n.shellDetailHint,
                  style: context.mc.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: context.mc.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(McRadii.lg),
          ),
          child: Icon(
            CupertinoIcons.bag_fill,
            color: context.mc.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.mc.foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(l10n.appSlogan, style: context.mc.textLabel),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: context.mc.hot),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.mc.foreground,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(McRadii.md),
      onPressed: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: context.mc.secondary,
          borderRadius: BorderRadius.circular(McRadii.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: context.mc.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.mc.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotRankRow extends StatelessWidget {
  const _HotRankRow({
    required this.post,
    required this.rank,
    required this.onTap,
  });

  final PostDto post;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = post.title?.trim().isNotEmpty == true
        ? post.title!.trim()
        : l10n.postUnnamed;
    final isTop3 = rank <= 3;
    final rankColor = isTop3 ? context.mc.hot : context.mc.secondaryLabel;

    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(McRadii.sm),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.mc.foreground,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_right,
              size: 12,
              color: context.mc.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}
