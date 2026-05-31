import 'package:share_plus/share_plus.dart';

import '../models/post.dart';

const _defaultPublicWebBaseUrl = String.fromEnvironment(
  'PUBLIC_WEB_BASE_URL',
  defaultValue: 'https://lumalis.luckyfishes.site',
);
const _postExcerptLength = 80;

class ShareService {
  const ShareService();

  String buildPostShareUrl(String postId) {
    final baseUri = Uri.parse(_normalizeBaseUrl(_defaultPublicWebBaseUrl));
    return baseUri.resolve('/post/$postId').toString();
  }

  String buildPostShareText(PostDto post) {
    final title = post.title?.trim().isNotEmpty == true
        ? post.title!.trim()
        : '来自光汇的帖子';
    final excerpt = _buildExcerpt(post.content);
    final url = buildPostShareUrl(post.id);

    if (excerpt.isEmpty) {
      return '$title\n$url';
    }

    return '$title\n$excerpt\n$url';
  }

  Future<void> sharePost(PostDto post) {
    return SharePlus.instance.share(
      ShareParams(text: buildPostShareText(post)),
    );
  }

  String _buildExcerpt(String? content) {
    final normalized = content?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.length <= _postExcerptLength) {
      return normalized;
    }

    return '${normalized.substring(0, _postExcerptLength).trimRight()}...';
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed;
    }
    return '$trimmed/';
  }
}
