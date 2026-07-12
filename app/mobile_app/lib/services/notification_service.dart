import '../models/api_response.dart';
import '../models/notification.dart';
import '../models/paged_result.dart';
import 'api_service.dart';

class NotificationService {
  final _api = ApiService().dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Notification response format error');
    }
    return data;
  }

  Future<PagedResult<NotificationDto>?> getNotifications({
    int pageIndex = 1,
    int pageSize = 10,
  }) async {
    final response = await _api.get(
      '/Notification',
      queryParameters: {'PageIndex': pageIndex, 'PageSize': pageSize},
    );
    final apiRes = ApiResponse<PagedResult<NotificationDto>>.fromJson(
      _asMap(response.data),
      (json) => PagedResult<NotificationDto>.fromJson(
        json as Map<String, dynamic>,
        (item) => NotificationDto.fromJson(item as Map<String, dynamic>),
      ),
    );
    return apiRes.data;
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get('/Notification/unread-count');
    final apiRes = ApiResponse<int>.fromJson(
      _asMap(response.data),
      (json) => json as int,
    );
    return apiRes.data ?? 0;
  }

  Future<bool> markAsRead(String id) async {
    final response = await _api.post('/Notification/$id/read');
    final apiRes = ApiResponse<Object?>.fromJson(
      _asMap(response.data),
      (json) => json,
    );
    return apiRes.code == 200 &&
        (apiRes.errorCode == null || apiRes.errorCode == 0);
  }

  Future<bool> markAllAsRead() async {
    final response = await _api.post('/Notification/read-all');
    final apiRes = ApiResponse<Object?>.fromJson(
      _asMap(response.data),
      (json) => json,
    );
    return apiRes.code == 200 &&
        (apiRes.errorCode == null || apiRes.errorCode == 0);
  }

  Future<PushSettingsDto?> getSettings() async {
    final response = await _api.get('/Notification/settings');
    final apiRes = ApiResponse<PushSettingsDto>.fromJson(
      _asMap(response.data),
      (json) => PushSettingsDto.fromJson(json as Map<String, dynamic>),
    );
    return apiRes.data;
  }

  Future<bool> updateSettings(PushSettingsDto settings) async {
    final response = await _api.put(
      '/Notification/settings',
      data: settings.toJson(),
    );
    final apiRes = ApiResponse<Object?>.fromJson(
      _asMap(response.data),
      (json) => json,
    );
    return apiRes.code == 200 &&
        (apiRes.errorCode == null || apiRes.errorCode == 0);
  }
}
