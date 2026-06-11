import 'package:dio/dio.dart';

const Map<int, String> _errorCodeMessages = {
  0: '操作成功',

  1000: '参数不能为空',
  1001: '参数格式不正确',
  1002: '参数超出允许范围',
  1003: '参数验证失败',

  2000: '资源已存在',
  2001: '操作失败',
  2002: '数据处理失败',
  2003: '当前状态不允许执行此操作',

  3000: '请先登录',
  3001: '权限不足',
  3002: '登录已过期，请重新登录',
  3003: '令牌无效',
  3004: '令牌已过期',
  3005: '不支持的第三方登录方式',

  4000: '资源不存在',

  4100: '用户不存在',
  4101: '账号已被禁用',
  4102: '该账号已被注册',
  4103: '密码错误',

  4200: '帖子不存在',
  4201: '帖子创建失败',
  4202: '帖子更新失败',
  4203: '无权删除该帖子',

  4300: '评论不存在',
  4301: '父评论不存在',
  4302: '评论创建失败',
  4303: '评论更新失败',
  4304: '无权删除该评论',

  5000: '服务器内部错误，请稍后重试',
  5001: '数据库操作失败',
  5002: '缓存服务异常，请稍后重试',
  5003: '网络连接异常，请检查网络',

  6000: '外部服务调用失败',
  6001: '外部服务响应超时',
  6002: '外部服务返回错误',
  6003: '外部服务未配置',

  7000: '操作过于频繁，请稍后重试',
  7001: '无效请求',
};

const String _defaultErrorMessage = '操作失败，请稍后重试';

String errorMessageFromCode(int? code, {String? fallback}) {
  if (code != null && code != 0 && _errorCodeMessages.containsKey(code)) {
    return _errorCodeMessages[code]!;
  }
  if (fallback != null && fallback.trim().isNotEmpty) {
    return fallback.trim();
  }
  return _defaultErrorMessage;
}

String extractErrorFromException(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorCode = data['errorCode'];
      if (errorCode is int && errorCode != 0) {
        return errorMessageFromCode(errorCode);
      }
      final detail = data['detail'] ?? data['message'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
    }

    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
  }

  final message = error.toString().trim();
  if (message.startsWith('Exception:')) {
    return message.substring('Exception:'.length).trim();
  }
  return message.isEmpty ? _defaultErrorMessage : message;
}
