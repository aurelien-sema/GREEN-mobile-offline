import 'package:flutter/foundation.dart';

/// NotificationService wrapper for local notifications.
/// Note: flutter_local_notifications temporarily disabled due to Android build conflicts.
/// This service provides stub implementations to maintain API compatibility.
class NotificationService {
  /// Initialize notification service (stub implementation)
  Future<void> initialize() async {
    debugPrint('[NotificationService] Initializing (stub mode - disabled for Android build compatibility)');
  }

  /// Show a simple notification (stub implementation)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    debugPrint('[NotificationService] showNotification: title="$title", body="$body"');
    // Notifications temporarily disabled - just log for debugging
  }

  /// Show progress notification (stub implementation)
  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    int id = 1,
  }) async {
    final percent = maxProgress > 0 ? (progress / maxProgress * 100).toInt() : 0;
    debugPrint('[NotificationService] showProgressNotification: title="$title", progress=$percent%');
  }

  /// Cancel notification (stub implementation)
  Future<void> cancelNotification(int id) async {
    debugPrint('[NotificationService] cancelNotification: id=$id');
  }

  /// Cancel all notifications (stub implementation)
  Future<void> cancelAllNotifications() async {
    debugPrint('[NotificationService] cancelAllNotifications called');
  }
}

final notificationService = NotificationService();
