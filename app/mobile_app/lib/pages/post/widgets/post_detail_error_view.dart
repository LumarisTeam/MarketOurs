import 'package:flutter/cupertino.dart';

import '../../../ui/app_widgets.dart';

class PostDetailErrorView extends StatelessWidget {
  const PostDetailErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppRetryState(
        title: '详情加载失败',
        description: message,
        icon: CupertinoIcons.doc_text,
        onRetry: onRetry,
      ),
    );
  }
}
