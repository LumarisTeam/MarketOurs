import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'auth_storage.dart';

class ApiService {
  late final Dio dio;
  static final ApiService _instance = ApiService._internal();
  static const String _apiBaseUrlOverride =
      'https://lumalisapi.luckyfishes.site';
  static const String _skipAuthExtraKey = 'skipAuth';
  static const String _skipUnauthorizedHandlerExtraKey =
      'skipUnauthorizedHandler';
  AuthStorage? _authStorage;
  Future<void> Function()? _onUnauthorized;
  bool _isHandlingUnauthorized = false;

  factory ApiService() => _instance;

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final shouldSkipAuth = options.extra[_skipAuthExtraKey] == true;
          final token = shouldSkipAuth
              ? null
              : await _authStorage?.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          final shouldSkipUnauthorizedHandler =
              e.requestOptions.extra[_skipUnauthorizedHandlerExtraKey] == true;
          if (e.response?.statusCode == 401 &&
              !shouldSkipUnauthorizedHandler &&
              !_isHandlingUnauthorized &&
              _onUnauthorized != null) {
            _isHandlingUnauthorized = true;
            try {
              await _onUnauthorized!.call();
            } finally {
              _isHandlingUnauthorized = false;
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  void configureAuth({
    required AuthStorage storage,
    Future<void> Function()? onUnauthorized,
  }) {
    _authStorage = storage;
    _onUnauthorized = onUnauthorized;
  }

  static Options anonymousOptions() {
    return Options(
      extra: {_skipAuthExtraKey: true, _skipUnauthorizedHandlerExtraKey: true},
    );
  }

  static String _resolveBaseUrl() {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }

    if (kDebugMode) {
      return 'http://localhost:5053';
    }

    if (kIsWeb) {
      return 'http://localhost:5053';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5053';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:5053';
      case TargetPlatform.fuchsia:
        return 'http://localhost:5053';
    }
  }
}
