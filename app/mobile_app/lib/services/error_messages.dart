import 'package:dio/dio.dart';

/// Maps backend ErrorCode values to human-readable messages (English fallbacks).
/// Kept in sync with backend ErrorCode.cs. Callers should use errorCode for
/// programmatic handling rather than parsing message strings.
///
/// Error code ranges:
///   0           Success
///   1000-1099   General / parameter errors
///   1100-1199   General business errors
///   2000-2099   Authentication errors
///   2100-2199   Authorization errors
///   3000-3099   User errors
///   4000-4099   Post errors
///   4100-4199   Comment errors
///   5000-5099   Follow / block errors
///   6000-6099   File errors
///   7000-7099   Like errors
///   8000-8099   System / infrastructure errors
///   8100-8199   External service errors
///   9000-9099   Platform / rate-limit errors
const Map<int, String> _errorCodeMessages = {
  // Success
  0: 'Operation succeeded',

  // General / parameter errors (1000-1099)
  1000: 'Parameter cannot be empty',
  1001: 'Parameter format is incorrect',
  1002: 'Parameter is out of allowed range',
  1003: 'Parameter validation failed',
  1004: 'Request body is missing',
  1005: 'Unsupported Content-Type',

  // General business errors (1100-1199)
  1100: 'Resource already exists',
  1101: 'Operation failed',
  1102: 'Data processing failed',
  1103: 'This operation is not allowed in the current state',
  1104: 'Too many requests, please try again later',
  1105: 'Resource has expired',

  // Authentication errors (2000-2099)
  2000: 'Please sign in first',
  2001: 'Invalid token',
  2002: 'Token has expired',
  2003: 'Session expired, please sign in again',
  2004: 'Refresh token is invalid or has expired',
  2005: 'Incorrect username or password',
  2006: 'Invalid OAuth authorization code',
  2007: 'Unsupported third-party login method',
  2008: 'Verification code is invalid or has expired',
  2009: 'Registration session expired, please start over',
  2010: 'Third-party account is not linked to a local account',
  2011: 'This third-party account is already linked to another account',
  2012: 'No linked account found, please sign in and link first',

  // Authorization errors (2100-2199)
  2100: 'Insufficient permissions',
  2101: 'Not authorized to modify another user\'s post',
  2102: 'Not authorized to delete another user\'s post',
  2103: 'Not authorized to modify another user\'s comment',
  2104: 'Not authorized to delete another user\'s comment',
  2105: 'Account has been disabled',
  2106: 'Account is not yet activated',

  // User errors (3000-3099)
  3000: 'User not found',
  3001: 'User has no linked email address',
  3002: 'User has no linked phone number',
  3003: 'This account already exists',
  3004: 'Email address is already registered',
  3005: 'Old password is incorrect',
  3006: 'Password verification failed',
  3007: 'Cannot operate on your own account',
  3008: 'Account has no linked email or phone; cannot send reset code',
  3009: 'Unsupported verification method',
  3010: 'Unsupported third-party platform',
  3011: 'This third-party account is not yet linked',

  // Post errors (4000-4099)
  4000: 'Post not found',
  4001: 'Failed to create post',
  4002: 'Failed to update post',

  // Comment errors (4100-4199)
  4100: 'Comment not found',
  4101: 'The comment being replied to does not exist',
  4102: 'Failed to create comment',
  4103: 'Failed to update comment',

  // Follow / block errors (5000-5099)
  5000: 'Cannot follow yourself',
  5001: 'Cannot block yourself',
  5002: 'Cannot follow a user who has blocked or been blocked by you',
  5003: 'Follow rate limit exceeded, please try again later',
  5004: 'Block rate limit exceeded, please try again later',

  // File errors (6000-6099)
  6000: 'File not found',
  6001: 'Unsupported file type',
  6002: 'File upload failed',
  6003: 'File size exceeds the limit',

  // Like errors (7000-7099)
  7000: 'Like rate limit exceeded, please try again later',
  7001: 'Already liked',
  7002: 'Not liked yet, cannot unlike',

  // System / infrastructure errors (8000-8099)
  8000: 'Internal server error, please try again later',
  8001: 'Database operation failed',
  8002: 'Cache service is unavailable',
  8003: 'Cache operation failed',
  8004: 'Network connection error, please check your connection',

  // External service errors (8100-8199)
  8100: 'External service call failed',
  8101: 'External service response timed out',
  8102: 'External service returned an error',
  8103: 'External service is not configured',
  8104: 'Failed to send email',
  8105: 'Failed to send SMS',

  // Platform / rate-limit errors (9000-9099)
  9000: 'Too many requests, please try again later',
  9001: 'IP address has been blacklisted',
};

const String _defaultErrorMessage = 'Operation failed, please try again later';

/// Returns a human-readable message for the given backend errorCode.
/// Prefers the errorCode map, then the optional fallback, then a default.
String errorMessageFromCode(int? code, {String? fallback}) {
  if (code != null && code != 0 && _errorCodeMessages.containsKey(code)) {
    return _errorCodeMessages[code]!;
  }
  if (fallback != null && fallback.trim().isNotEmpty) {
    return fallback.trim();
  }
  return _defaultErrorMessage;
}

/// Extracts a human-readable error message from an exception object
/// (DioException or other).
String extractErrorFromException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out, please check your network and try again';
      case DioExceptionType.sendTimeout:
        return 'Upload timed out, please switch networks or reduce the number of images';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long, please try again later';
      case DioExceptionType.connectionError:
        return 'Network connection failed, please check your network and try again';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }

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
