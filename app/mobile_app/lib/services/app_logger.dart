import 'dart:convert';

import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(
    String tag,
    String message, {
    Map<String, Object?>? context,
  }) {
    _log('INFO', tag, message, context: context);
  }

  static void warn(
    String tag,
    String message, {
    Map<String, Object?>? context,
  }) {
    _log('WARN', tag, message, context: context);
  }

  static void error(
    String tag,
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      'ERROR',
      tag,
      message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    String level,
    String tag,
    String message, {
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer(
      '[${DateTime.now().toIso8601String()}][$level][$tag] $message',
    );

    if (context != null && context.isNotEmpty) {
      buffer.write(' | ${_stringify(context)}');
    }

    if (error != null) {
      buffer.write(' | error=$error');
    }

    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }

    debugPrint(buffer.toString());
  }

  static String stringifyValue(Object? value) => _stringify(value);

  static String _stringify(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is String) {
      return value;
    }

    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
