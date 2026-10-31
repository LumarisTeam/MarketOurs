import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:luamris_ui/luamris_ui.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import '../../components/app_avatar.dart';
import '../../models/post.dart';
import '../../utils/date_formatters.dart';

/// Single-line post row used by the desktop list column.
///
/// Keeps the avatar/title/excerpt/timestamp rhythm of the mobile card while
/// staying compact enough for a 340px wide column.
class CompactPostTile extends StatelessWidget {
  const CompactPostTile({
    super.key,
    required this.post,
    required this.onTap,
    this.isSelected = false,
    this.rank,
  });

  final PostDto post;
  final VoidCallback onTap;
  final bool isSelected;

  /// Optional 1-based rank shown as a leading badge (hot list).
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = post.title?.trim().isNotEmpty == true
        ? post.title!.trim()
        : l10n.postUnnamed;
    final content = post.content?.trim();
    final summary = content?.isNotEmpty == true ? content! : l10n.postNoContent;
    final time = formatRelativeDateTime(post.createdAt, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: CupertinoButton(
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(McRadii.md),
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? context.mc.primary.withValues(alpha: 0.12)
                : null,
            borderRadius: BorderRadius.circular(McRadii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank != null) ...[
                _RankBadge(rank: rank!),
                const SizedBox(width: 8),
              ] else ...[
                AppAvatar(
                  url: post.author?.avatar,
                  name: post.author?.name,
                  size: 34,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? context.mc.primary
                            : context.mc.foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: context.mc.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: context.mc.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final color = isTop3 ? context.mc.hot : context.mc.secondaryLabel;
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(top: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop3
            ? context.mc.hot.withValues(alpha: 0.12)
            : context.mc.muted,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
