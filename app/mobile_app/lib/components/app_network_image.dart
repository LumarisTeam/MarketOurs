import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

import '../services/image_cache_manager.dart';
import '../ui/app_theme.dart';

/// A drop-in replacement for `Image.network` that adds disk caching,
/// configurable memory-cache dimensions, and consistent Cupertino-style
/// loading / error placeholders.
///
/// ### Automatic decode-size calculation
///
/// When [width] (or [height]) is a finite number the widget computes a
/// matching [memCacheWidth] (memCacheHeight) as
/// `(displaySize × devicePixelRatio).round()`.  This guarantees the in-memory
/// bitmap is never larger than what the screen can actually show — a
/// 88×88 logical-pixel thumbnail on a 3× display is decoded at ≈264 px
/// instead of the full uploaded resolution (often 1920 px).
///
/// Pass explicit [cacheWidth]/[cacheHeight] to override, or leave both
/// `null` to decode at full resolution (useful for full-screen viewers where
/// fidelity matters more than memory).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.gaplessPlayback = false,
    this.loadingPlaceholder,
    this.errorPlaceholder,
    this.cacheWidth,
    this.cacheHeight,
  });

  /// Remote image URL.
  final String url;

  /// Display width in logical pixels.  Used to compute [memCacheWidth] unless
  /// overridden by [cacheWidth].
  final double? width;

  /// Display height in logical pixels.  Used to compute [memCacheHeight]
  /// unless overridden by [cacheHeight].
  final double? height;

  /// How the image should be inscribed into the box.
  final BoxFit? fit;

  /// Optional clip radius applied via an outer [ClipRRect].
  final double? borderRadius;

  /// Whether to show the previously-loaded image while the new one loads.
  /// Maps to [CachedNetworkImage.useOldImageOnUrlChange].
  final bool gaplessPlayback;

  /// Placeholder shown while the image is loading.
  ///
  /// Default: a [CupertinoActivityIndicator] centered on
  /// [AppColors.secondary] background.
  final Widget? loadingPlaceholder;

  /// Widget shown when the image fails to load.
  ///
  /// Default: a [CupertinoIcons.photo] icon on [AppColors.secondary]
  /// background.
  final Widget? errorPlaceholder;

  /// Explicit memory-cache decode width (pixels).  Overrides the automatic
  /// calculation derived from [width].
  final int? cacheWidth;

  /// Explicit memory-cache decode height (pixels).  Overrides the automatic
  /// calculation derived from [height].
  final int? cacheHeight;

  // ---- helpers -----------------------------------------------------------

  static int? _resolveCacheDim(double? displaySize, int? override, BuildContext context) {
    if (override != null) return override;
    if (displaySize == null || displaySize == double.infinity) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (displaySize * dpr).round();
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final resolvedMemCacheWidth = _resolveCacheDim(width, cacheWidth, context);
    final resolvedMemCacheHeight = _resolveCacheDim(height, cacheHeight, context);

    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      cacheManager: AppImageCacheManager(),
      memCacheWidth: resolvedMemCacheWidth,
      memCacheHeight: resolvedMemCacheHeight,
      placeholder: (context, _) =>
          loadingPlaceholder ?? _defaultLoadingPlaceholder(context),
      errorWidget: (context, _, error) =>
          errorPlaceholder ?? _defaultErrorPlaceholder(context),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      useOldImageOnUrlChange: gaplessPlayback,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: image,
      );
    }

    return image;
  }

  static Widget _defaultLoadingPlaceholder(BuildContext context) {
    return Container(
      color: CupertinoDynamicColor.resolve(AppColors.secondary, context),
      child: const Center(child: CupertinoActivityIndicator(radius: 10)),
    );
  }

  static Widget _defaultErrorPlaceholder(BuildContext context) {
    return Container(
      color: CupertinoDynamicColor.resolve(AppColors.secondary, context),
      child: Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 24,
          color: CupertinoDynamicColor.resolve(
            AppColors.mutedForeground,
            context,
          ),
        ),
      ),
    );
  }
}
