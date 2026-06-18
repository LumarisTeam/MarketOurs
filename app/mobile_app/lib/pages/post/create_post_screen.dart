import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../components/editable_image_wrap.dart';
import '../../components/post_editor_form.dart';
import '../../components/post_tag_selector.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_feed_provider.dart';
import '../../services/error_messages.dart';
import '../../router/app_router.dart';
import '../../services/file_service.dart';
import '../../services/image_compression_service.dart';
import '../../ui/app_feedback.dart';
import '../../utils/dto_validation.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _fileService = FileService();
  final List<EditableImageEntry> _imageEntries = [];
  int _imageIdCounter = 0;
  List<PostTagDto> _tags = const [];
  PostTagDto? _selectedTag;
  bool _isSubmitting = false;
  double? _uploadProgress;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() {
      for (final file in picked) {
        _imageEntries.add(EditableImageEntry(
          id: ValueKey('new-${_imageIdCounter++}'),
          displayUrl: file.path,
          localFile: file,
        ));
      }
    });
  }

  void _removeImageEntry(String id) {
    setState(() => _imageEntries.removeWhere((e) => e.id.toString() == id));
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      // Swap: the dragged item takes the drop target's position.
      final entry = _imageEntries[oldIndex];
      _imageEntries[oldIndex] = _imageEntries[newIndex];
      _imageEntries[newIndex] = entry;
    });
  }

  Future<void> _loadTags() async {
    try {
      final response = await ref.read(postServiceProvider).getPostTags();
      if (!mounted) return;
      setState(() => _tags = response.data ?? const <PostTagDto>[]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _tags = const <PostTagDto>[]);
    }
  }

  Future<void> _selectTag() async {
    final nextTag = await showPostTagPicker(
      context,
      tags: _tags,
      selectedTag: _selectedTag,
    );
    if (!mounted) return;
    setState(() => _selectedTag = nextTag);
  }

  Future<void> _submit() async {
    final authState = ref.read(authControllerProvider).asData?.value;
    final user = authState?.user;
    if (user == null) {
      context.go(AppRoutePaths.login);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Compress images to WebP before upload to reduce file size
    final compressed = <CompressedImage>[];
    try {
      // Fetch upload key and compress images in parallel — they are independent.
      // This saves one network round-trip worth of latency.
      String? uploadKey;
      if (_imageEntries.isNotEmpty) {
        final results = await Future.wait([
          _fileService.getUploadKey().then(
            (r) => (r.data?['key'] as String?) ?? '',
          ),
          ImageCompressionService.compressAll(
            _imageEntries.map((e) => e.localFile!).toList(),
            quality: ImageCompressionService.postImageQuality,
            maxWidth: ImageCompressionService.postMaxWidth,
            maxHeight: ImageCompressionService.postMaxHeight,
          ),
        ]);
        uploadKey = results[0] as String?;
        if (uploadKey?.isEmpty == true) {
          uploadKey = null;
        }
        compressed.addAll(results[1] as List<CompressedImage>);
      }

      final uploadedImages = compressed.isEmpty
          ? <String>[]
          : (await _fileService.uploadStream(
                  compressed.map(ImageCompressionService.toXFile).toList(),
                  key: uploadKey,
                  onProgress: (fraction) {
                    if (mounted) setState(() => _uploadProgress = fraction);
                  },
                )).data ??
                <String>[];

      final response = await ref
          .read(postServiceProvider)
          .createPost(
            PostCreateDto(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              images: uploadedImages,
              userId: user.id,
              uploadKey: uploadKey,
              tagId: _selectedTag?.id,
            ),
          );

      final post = response.data;
      if (post == null) throw Exception(response.message ?? '帖子创建失败');

      if (!mounted) return;

      await AppFeedback.showSuccess(context, message: '帖子已发布');
      if (!mounted) return;
      context.pushReplacement(buildPostDetailLocation(post.id));
    } catch (error) {
      if (!mounted) return;
      await AppFeedback.showError(
        context,
        message: extractErrorFromException(error),
      );
    } finally {
      // Clean up temp compressed files regardless of outcome
      ImageCompressionService.cleanup(compressed);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('发布帖子'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSubmitting ? null : _submit,
          child: Text(
            _isSubmitting ? '正在发布' : '发布',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              PostEditorForm(
                layout: PostEditorLayout.page,
                titleController: _titleController,
                contentController: _contentController,
                selectedTag: _selectedTag,
                existingImages: const [],
                localImages: const [],
                onPickTag: _isSubmitting ? null : _selectTag,
                onPickImages: _isSubmitting ? null : _pickImages,
                reorderableEntries: _imageEntries,
                onReorderImages: _isSubmitting ? null : _reorderImages,
                onRemoveImageEntry: _isSubmitting ? null : _removeImageEntry,
                onSubmit: _isSubmitting ? null : _submit,
                submitLabel: _isSubmitting ? '发布中...' : '立即发布',
                uploadProgress: _uploadProgress,
                titleValidator: (v) => requiredMaxValidator(
                  v,
                  emptyMessage: '请输入标题',
                  max: DtoLimits.postTitleMax,
                  maxMessage: '标题长度不能超过 ${DtoLimits.postTitleMax} 位',
                ),
                contentValidator: (v) => requiredMaxValidator(
                  v,
                  emptyMessage: '请输入内容',
                  max: DtoLimits.postContentMax,
                  maxMessage: '内容长度不能超过 ${DtoLimits.postContentMax} 位',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
