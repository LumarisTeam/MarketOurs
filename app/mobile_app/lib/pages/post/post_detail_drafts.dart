import 'package:image_picker/image_picker.dart';

import '../../components/editable_image_wrap.dart';
import '../../models/post.dart';

/// Form result returned by the comment editor sheet.
class CommentDraft {
  const CommentDraft({
    required this.content,
    this.existingImages = const [],
    this.newImages = const [],
    this.reorderedEntries,
  });

  final String content;
  final List<String> existingImages;
  final List<XFile> newImages;
  final List<EditableImageEntry>? reorderedEntries;
}

/// Form result returned by the post editor sheet.
class PostDraft {
  const PostDraft({
    required this.title,
    required this.content,
    this.tag,
    this.reorderedEntries,
  });

  final String title;
  final String content;
  final PostTagDto? tag;
  final List<EditableImageEntry>? reorderedEntries;
}
