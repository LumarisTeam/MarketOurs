import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Singleton cache manager for network images.
///
/// All [AppNetworkImage] widgets share this cache so that an image downloaded
/// once (at any resolution) is reused across the app from disk.  Limits are
/// sized conservatively — the LRU eviction makes sure we stay within bounds
/// even when images are large.
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'marketOursImageCache';

  static final AppImageCacheManager _instance = AppImageCacheManager._();

  /// Returns the singleton instance.
  factory AppImageCacheManager() => _instance;

  AppImageCacheManager._()
      : super(
          Config(
            _key,
            maxNrOfCacheObjects: 5000,
            stalePeriod: const Duration(days: 30),
            repo: JsonCacheInfoRepository(databaseName: _key),
            fileService: HttpFileService(),
          ),
        );
}
