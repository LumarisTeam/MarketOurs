import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class MacosWindow {
  static const _channel = MethodChannel('site.xauat.marketours/window');

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static void startDragging() {
    if (isMacOS) unawaited(_channel.invokeMethod<void>('startDragging'));
  }

  static void zoom() {
    if (isMacOS) unawaited(_channel.invokeMethod<void>('zoom'));
  }
}
