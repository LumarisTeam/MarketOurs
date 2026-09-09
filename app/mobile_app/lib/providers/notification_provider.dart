import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final unreadNotificationCountProvider =
    AsyncNotifierProvider<UnreadNotificationCountNotifier, int>(
      UnreadNotificationCountNotifier.new,
    );

class UnreadNotificationCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.read(notificationServiceProvider).getUnreadCount();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationServiceProvider).getUnreadCount(),
    );
  }

  void clear() => state = const AsyncData(0);
}
