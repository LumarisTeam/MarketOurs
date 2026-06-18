import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:gal/gal.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../ui/app_feedback.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final Dio _dio = Dio();
  final Map<String, Size> _imageSizes = {};
  final Map<String, ImageStream> _imageStreams = {};
  final Map<String, ImageStreamListener> _imageStreamListeners = {};
  final Set<String> _resolvingImages = {};
  late int _currentIndex;
  late PageController _pageController;
  late List<PhotoViewController> _photoControllers;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _photoControllers = List.generate(
      widget.images.length,
      (_) => PhotoViewController(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final imageUrl in widget.images) {
      _resolveImageSize(imageUrl);
    }
  }

  @override
  void dispose() {
    for (final controller in _photoControllers) {
      controller.dispose();
    }
    for (final entry in _imageStreams.entries) {
      final listener = _imageStreamListeners[entry.key];
      if (listener != null) {
        entry.value.removeListener(listener);
      }
    }
    _pageController.dispose();
    super.dispose();
  }

  String? get _currentImageUrl {
    if (widget.images.isEmpty) {
      return null;
    }
    if (_currentIndex < 0 || _currentIndex >= widget.images.length) {
      return null;
    }
    return widget.images[_currentIndex];
  }

  void _resolveImageSize(String imageUrl) {
    if (_imageSizes.containsKey(imageUrl) ||
        _resolvingImages.contains(imageUrl)) {
      return;
    }

    _resolvingImages.add(imageUrl);
    final stream = NetworkImage(
      imageUrl,
    ).resolve(createLocalImageConfiguration(context));

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        final size = Size(
          imageInfo.image.width.toDouble(),
          imageInfo.image.height.toDouble(),
        );
        _imageStreams.remove(imageUrl)?.removeListener(listener);
        _imageStreamListeners.remove(imageUrl);
        _resolvingImages.remove(imageUrl);

        if (!mounted) {
          return;
        }

        if (synchronousCall) {
          _imageSizes[imageUrl] = size;
          return;
        }

        setState(() {
          _imageSizes[imageUrl] = size;
        });
      },
      onError: (_, stackTrace) {
        _imageStreams.remove(imageUrl)?.removeListener(listener);
        _imageStreamListeners.remove(imageUrl);
        _resolvingImages.remove(imageUrl);
      },
    );

    _imageStreams[imageUrl] = stream;
    _imageStreamListeners[imageUrl] = listener;
    stream.addListener(listener);
  }

  void _handleBackdropTap(TapUpDetails details) {
    if (_didTapImageBackdrop(details.localPosition)) {
      Navigator.of(context).pop();
    }
  }

  bool _didTapImageBackdrop(Offset tapPosition) {
    final imageUrl = _currentImageUrl;
    if (imageUrl == null) {
      return false;
    }

    final imageSize = _imageSizes[imageUrl];
    if (imageSize == null || _photoControllers.isEmpty) {
      return false;
    }

    final viewportSize = MediaQuery.sizeOf(context);
    final controllerValue = _photoControllers[_currentIndex].value;
    final scale =
        controllerValue.scale ?? _containedScale(viewportSize, imageSize);
    final displayedSize = Size(
      imageSize.width * scale,
      imageSize.height * scale,
    );
    final displayedRect = Rect.fromCenter(
      center: viewportSize.center(Offset.zero) + controllerValue.position,
      width: displayedSize.width,
      height: displayedSize.height,
    );

    return !displayedRect.contains(tapPosition);
  }

  double _containedScale(Size viewportSize, Size imageSize) {
    return (viewportSize.width / imageSize.width).clamp(0, double.infinity) <
            (viewportSize.height / imageSize.height).clamp(0, double.infinity)
        ? viewportSize.width / imageSize.width
        : viewportSize.height / imageSize.height;
  }

  Future<void> _showImageActionSheet() async {
    final imageUrl = _currentImageUrl;
    if (imageUrl == null) {
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('图片操作'),
        message: Text('当前图片：${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _saveCurrentImage(imageUrl);
            },
            child: const Text('保存图片'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await _shareCurrentImage(imageUrl);
            },
            child: const Text('转发图片'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetContext).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  Future<void> _saveCurrentImage(String imageUrl) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (!mounted) {
            return;
          }
          await AppFeedback.showError(context, message: '没有相册权限，无法保存图片');
          return;
        }
      }

      final downloaded = await _downloadImageFile(imageUrl);
      try {
        await Gal.putImage(downloaded.file.path);
      } finally {
        await _deleteTempFile(downloaded.file);
      }

      if (!mounted) {
        return;
      }
      await AppFeedback.showSuccess(context, message: '图片已保存到系统相册');
    } catch (_) {
      if (!mounted) {
        return;
      }
      await AppFeedback.showError(context, message: '保存图片失败，请稍后重试');
    }
  }

  Future<void> _shareCurrentImage(String imageUrl) async {
    try {
      final downloaded = await _downloadImageFile(imageUrl);
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(downloaded.file.path, mimeType: downloaded.mimeType)],
            title: '转发图片',
            sharePositionOrigin: _sharePositionOrigin,
          ),
        );
      } finally {
        await _deleteTempFile(downloaded.file);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      await AppFeedback.showError(context, message: '转发图片失败，请稍后重试');
    }
  }

  Future<_DownloadedImageFile> _downloadImageFile(String imageUrl) async {
    final response = await _dio.get<List<int>>(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Image download failed');
    }

    final fileName = _buildFileName(
      imageUrl,
      response.headers.value(Headers.contentTypeHeader),
    );
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    return _DownloadedImageFile(
      file: file,
      mimeType: _resolveMimeType(
        fileName,
        response.headers.value(Headers.contentTypeHeader),
      ),
    );
  }

  Rect? get _sharePositionOrigin {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  String _buildFileName(String imageUrl, String? contentType) {
    final uri = Uri.tryParse(imageUrl);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    final sanitized = lastSegment.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

    if (sanitized.contains('.') && !sanitized.endsWith('.')) {
      return 'marketours_${DateTime.now().millisecondsSinceEpoch}_$sanitized';
    }

    final extension = _extensionFromContentType(contentType) ?? 'jpg';
    return 'marketours_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  String _resolveMimeType(String fileName, String? contentType) {
    final normalizedContentType = contentType?.split(';').first.trim();
    if (normalizedContentType != null && normalizedContentType.isNotEmpty) {
      return normalizedContentType;
    }

    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex >= 0
        ? fileName.substring(dotIndex + 1).toLowerCase()
        : '';

    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String? _extensionFromContentType(String? contentType) {
    final normalized = contentType?.split(';').first.trim().toLowerCase();
    switch (normalized) {
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'image/heic':
        return 'heic';
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      default:
        return null;
    }
  }

  Future<void> _deleteTempFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (context, index) {
              final url = widget.images[index];
              final isGif = url.toLowerCase().contains('.gif');
              if (isGif) {
                return PhotoViewGalleryPageOptions.customChild(
                  controller: _photoControllers[index],
                  childSize: _imageSizes[url],
                  child: Center(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        CupertinoIcons.photo,
                        color: CupertinoColors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'image_$url'),
                );
              }
              return PhotoViewGalleryPageOptions(
                controller: _photoControllers[index],
                imageProvider: NetworkImage(url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: 'image_$url'),
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => const Center(
              child: CupertinoActivityIndicator(color: CupertinoColors.white),
            ),
            pageController: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            backgroundDecoration: const BoxDecoration(
              color: CupertinoColors.black,
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _handleBackdropTap,
              onLongPress: _showImageActionSheet,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.white,
                size: 32,
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadedImageFile {
  const _DownloadedImageFile({required this.file, required this.mimeType});

  final File file;
  final String mimeType;
}
