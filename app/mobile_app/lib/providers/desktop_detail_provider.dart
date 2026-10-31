import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Post id currently shown in the desktop detail column.
///
/// `null` means nothing is selected; the desktop shell then shows the welcome
/// pane instead of an embedded post detail.
final desktopDetailProvider =
    NotifierProvider<DesktopDetailNotifier, String?>(DesktopDetailNotifier.new);

class DesktopDetailNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String postId) {
    if (postId.isEmpty || state == postId) return;
    state = postId;
  }

  void clear() {
    if (state == null) return;
    state = null;
  }
}
