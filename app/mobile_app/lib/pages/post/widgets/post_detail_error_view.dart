import 'package:flutter/cupertino.dart';

import '../../../../l10n/app_localizations.dart';
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
        title: AppLocalizations.of(context).detailLoadFailed,
        description: message,
        icon: CupertinoIcons.doc_text,
        onRetry: onRetry,
      ),
    );
  }
}
