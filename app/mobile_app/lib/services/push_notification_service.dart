import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';

import '../models/api_response.dart';
import '../router/app_router.dart';
import 'api_service.dart';
import 'app_logger.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  AppLogger.info(
    'PushNotificationService',
    'Background local notification tapped',
    context: {'payload': response.payload},
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String provider = 'jpush';
  static const String channelId = 'marketours_notifications';
  static const String channelName = '光汇 通知';
  static const String channelDescription = '用于评论回复、热门动态与系统提醒';
  static const String _tokenEndpoint = '/User/push-token';

  final Dio _api = ApiService().dio;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final JPushFlutterInterface _jpush = JPush.newJPush();

  bool _localNotificationsReady = false;
  bool _initialized = false;
  bool _isSyncingToken = false;
  String? _registeredToken;
  GoRouter? _router;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize({required GoRouter router}) async {
    _router = router;

    if (!isSupported) {
      AppLogger.info(
        'PushNotificationService',
        'Skipping initialization on unsupported platform',
      );
      return;
    }

    if (_initialized) {
      return;
    }

    await _initializeLocalNotifications();
    await _initializeJPush();
    _initialized = true;
  }

  Future<void> syncCurrentToken() async {
    if (!isSupported || _isSyncingToken) return;

    _isSyncingToken = true;
    try {
      final registrationId = await _waitForRegistrationId();
      if (registrationId != null && registrationId.isNotEmpty) {
        await _registerToken(registrationId);
      } else {
        AppLogger.warn(
          'PushNotificationService',
          'JPush registration id is still empty after retries',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'PushNotificationService',
        'Failed to sync current JPush registration id',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncingToken = false;
    }
  }

  Future<void> clearRegisteredToken() async {
    if (!isSupported) return;

    try {
      await _updateTokenOnBackend('');
      _registeredToken = null;
      AppLogger.info(
        'PushNotificationService',
        'Cleared registered push token on logout',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'PushNotificationService',
        'Failed to clear registered push token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> dispose() async {}

  Future<void> _initializeJPush() async {
    _jpush.addEventHandler(
      onReceiveNotification: (message) async {
        // await _handleForegroundNotification(message);
      },
      onOpenNotification: (message) async {
        _handleNotificationTap(message);
      },
      onConnected: (message) async {
        AppLogger.info(
          'PushNotificationService',
          'JPush connected',
          context: {'message': AppLogger.stringifyValue(message)},
        );
        unawaited(syncCurrentToken());
      },
      onCommandResult: (message) async {
        AppLogger.info(
          'PushNotificationService',
          'Received JPush command result',
          context: {'message': AppLogger.stringifyValue(message)},
        );
      },
    );

    try {
      _jpush.setup(
        appKey: '',
        channel: 'developer-default',
        production: false,
        debug: !kReleaseMode,
      );
      _jpush.applyPushAuthority(
        const NotificationSettingsIOS(sound: true, alert: true, badge: true),
      );
      _jpush.requestRequiredPermission();
      await syncCurrentToken();
    } catch (error, stackTrace) {
      AppLogger.error(
        'PushNotificationService',
        'JPush initialization failed. Push notifications are disabled.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _waitForRegistrationId() async {
    const delays = <Duration>[
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    for (final delay in delays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      final registrationId = await _jpush.getRegistrationID();
      final normalized = registrationId.trim();
      if (normalized.isNotEmpty) {
        AppLogger.info(
          'PushNotificationService',
          'Fetched JPush registration id',
          context: {'registrationId': normalized},
        );
        return normalized;
      }
    }

    return null;
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_marketours_notification',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(androidChannel);

    _localNotificationsReady = true;
  }

  Future<void> _registerToken(String token) async {
    if (token == _registeredToken) {
      return;
    }

    try {
      await _updateTokenOnBackend(token);
      _registeredToken = token;
      AppLogger.info(
        'PushNotificationService',
        'Registered push token successfully',
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'PushNotificationService',
        'Failed to register push token',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _updateTokenOnBackend(String token) async {
    final response = await _api.post(
      _tokenEndpoint,
      data: {'provider': token.isEmpty ? null : provider, 'token': token},
    );
    final apiRes = ApiResponse<Object?>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    final success =
        apiRes.code == 200 &&
        (apiRes.errorCode == null || apiRes.errorCode == 0);
    if (!success) {
      throw Exception(apiRes.message ?? '推送 Token 更新失败');
    }
  }

  Future<void> _handleForegroundNotification(Map<dynamic, dynamic> message) async {
    final extras = _extractPayloadData(message);
    final title = _extractString(message, ['title', 'cn_title']) ?? '光汇通知';
    final body = _extractString(message, ['alert', 'message']) ?? '';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_stat_marketours_notification',
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(extras),
    );
  }

  Future<void> _onLocalNotificationTapped(NotificationResponse response) async {
    _handlePayloadNavigation(response.payload);
  }

  void _handleNotificationTap(Map<dynamic, dynamic> message) {
    _navigateFromData(_extractPayloadData(message));
  }

  void _handlePayloadNavigation(String? payload) {
    if (payload == null || payload.isEmpty) {
      _router?.go(AppRoutePaths.notifications);
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _navigateFromData(decoded);
        return;
      }
    } catch (error) {
      AppLogger.warn(
        'PushNotificationService',
        'Failed to decode local notification payload',
        context: {'payload': payload, 'error': error.toString()},
      );
    }

    _router?.go(AppRoutePaths.notifications);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final targetId = data['targetId']?.toString().trim();
    if (targetId != null && targetId.isNotEmpty) {
      _router?.go(buildPostDetailLocation(targetId));
      return;
    }

    _router?.go(AppRoutePaths.notifications);
  }

  Map<String, dynamic> _extractPayloadData(Map<dynamic, dynamic> message) {
    final extras = message['extras'];
    if (extras is Map) {
      return Map<String, dynamic>.from(
        extras.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    final content = message['content'];
    if (content is Map && content['n_extras'] is Map) {
      return Map<String, dynamic>.from(
        (content['n_extras'] as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }

    return <String, dynamic>{};
  }

  String? _extractString(Map<dynamic, dynamic> message, List<String> keys) {
    for (final key in keys) {
      final value = message[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    final content = message['content'];
    if (content is Map) {
      for (final key in keys) {
        final value = content[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }
}
