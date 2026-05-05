import 'dart:async';
import 'package:flutter/services.dart';

class ScreenshotAction {
  final String action; // 'save' | 'stack' | 'addtask'
  final String uri;

  const ScreenshotAction(this.action, this.uri);
}

/// Manages the native screenshot-detection foreground service and delivers
/// notification action events to Flutter as a broadcast stream.
class ScreenshotWatcherService {
  ScreenshotWatcherService._();

  static const _channel =
      MethodChannel('com.example.recall_os_flutter/screenshot');

  static final _ctrl = StreamController<ScreenshotAction>.broadcast();

  /// Subscribe to receive screenshot notification actions.
  static Stream<ScreenshotAction> get events => _ctrl.stream;

  /// Call once in main() — sets up the incoming method call handler.
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onScreenshotAction') {
        final args = Map<String, String>.from(call.arguments as Map);
        _ctrl.add(ScreenshotAction(args['action']!, args['uri']!));
      }
    });
  }

  /// Start the native foreground service.
  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('startService');
    } catch (_) {}
  }

  /// Stop the native foreground service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopService');
    } catch (_) {}
  }

  /// Requests READ_MEDIA_IMAGES (Android 13+) or READ_EXTERNAL_STORAGE
  /// (Android 12 and below) at runtime. Returns true if already granted.
  /// Must be called while the activity is visible (foreground).
  static Future<bool> requestMediaPermission() async {
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestMediaPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Resolves a content:// URI to a real file path by copying it to the app
  /// cache via a native call. Returns the original string unchanged if it is
  /// already a file path (i.e. does not start with "content://").
  static Future<String?> resolveUri(String uri) async {
    if (!uri.startsWith('content://')) return uri;
    try {
      return await _channel.invokeMethod<String>(
        'resolveContentUri',
        {'uri': uri},
      );
    } catch (_) {
      return null;
    }
  }

  /// Queries MediaStore for the total number of images inside any folder
  /// named "Screenshots" on the device. Returns 0 on failure or if permission
  /// has not been granted yet.
  static Future<int> countDeviceScreenshots() async {
    try {
      final count =
          await _channel.invokeMethod<int>('countDeviceScreenshots');
      return count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Poll native for an action that arrived while the app was cold-starting.
  /// Call this after subscribing to [events] so the action reaches a listener.
  static Future<void> checkPending() async {
    try {
      final raw = await _channel.invokeMethod<Map>('getPendingAction');
      if (raw != null) {
        _ctrl.add(ScreenshotAction(
          raw['action'] as String,
          raw['uri'] as String,
        ));
      }
    } catch (_) {}
  }
}
