import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:luamris_ui/luamris_ui.dart';

import '../pages/post/image_viewer_screen.dart';
import 'app_network_image.dart';

const int postImageGridMaxImages = 9;

/// Displays image-only posts using the same compact layout as Moments.
class PostImageGrid extends StatelessWidget {
  const PostImageGrid({
    super.key,
    required this.images,
    this.enableViewer = true,
    this.compact = false,
  });

  final List<String> images;
  final bool enableViewer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final visibleImages = images.take(postImageGridMaxImages).toList();
    final columns = visibleImages.length == 4 ? 2 : 3;
    final widthFactor = visibleImages.length == 4 ? 0.66 : 0.87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final gridWidth = availableWidth * widthFactor;
        final spacing = compact ? 4.0 : 8.0;
        final tileSize = (gridWidth - spacing * (columns - 1)) / columns;

        Widget buildTile(int index) {
          final image = visibleImages[index];
          final tile = ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 5 : McRadii.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: context.mc.secondary,
                  child: AppNetworkImage(
                    url: image,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorPlaceholder: Icon(
                      CupertinoIcons.photo,
                      color: context.mc.secondaryLabel,
                    ),
                  ),
                ),
                if (index == postImageGridMaxImages - 1 &&
                    images.length > postImageGridMaxImages)
                  ColoredBox(
                    color: CupertinoColors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Text(
                        '+${images.length - postImageGridMaxImages}',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );

          if (!enableViewer) return tile;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) =>
                      ImageViewerScreen(images: images, initialIndex: index),
                ),
              );
            },
            child: Hero(tag: 'image_$image', child: tile),
          );
        }

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: gridWidth,
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var index = 0; index < visibleImages.length; index++)
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: buildTile(index),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
