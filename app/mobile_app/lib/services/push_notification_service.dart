import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../firebase_options.dart';
import '../models/api_response.dart';
import '../router/app_router.dart';
import 'api_service.dart';
import 'app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info(
    'PushNotificationService',
    'Received background FCM message',
    context: {'messageId': message.messageId, 'data': message.data},
  );
}

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

  static const String channelId = 'marketours_notifications';
  static const String channelName = '光汇 通知';
  static const String channelDescription = '用于评论回复、热门动态与系统提醒';
  static const String _tokenEndpoint = '/User/push-token';

  final Dio _api = ApiService().dio;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _localNotificationsReady = false;
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
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

    if (!DefaultFirebaseOptions.isConfigured) {
      AppLogger.warn(
        'PushNotificationService',
        'Firebase options are not configured. Skipping push setup.',
      );
      return;
    }

    if (_initialized) {
      await _handleInitialMessage();
      return;
    }

    await _initializeLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final permission = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      criticalAlert: false,
      provisional: false,
      carPlay: false,
    );
    AppLogger.info(
      'PushNotificationService',
      'Notification permission updated',
      context: {'status': permission.authorizationStatus.name},
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _messageOpenedSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageTap,
    );

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    _initialized = true;
    await _handleInitialMessage();
  }

  Future<void> syncCurrentToken() async {
    if (!isSupported || !DefaultFirebaseOptions.isConfigured) return;
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }
  }

  Future<void> clearRegisteredToken() async {
    if (!isSupported || !DefaultFirebaseOptions.isConfigured) return;

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

  Future<void> dispose() async {
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _messageOpenedSubscription = null;
    _tokenRefreshSubscription = null;
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
    final response = await _api.post(_tokenEndpoint, data: token);
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

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? '光汇通知';
    final body = message.notification?.body ?? '';

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
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _onLocalNotificationTapped(NotificationResponse response) async {
    _handlePayloadNavigation(response.payload);
  }

  void _handleMessageTap(RemoteMessage message) {
    _navigateFromData(message.data);
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
}
