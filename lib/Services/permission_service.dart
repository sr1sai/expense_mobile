import 'package:permission_handler/permission_handler.dart';

/// Service to handle SMS and notification permissions
class PermissionService {
  /// Request SMS and notification permissions if not already granted
  /// Returns true if both permissions are granted, false otherwise
  static Future<bool> requestSmsPermission() async {
    print(
      '==================== REQUESTING SMS PERMISSION ====================',
    );

    // First request notification permission (required for Android 13+)
    final notificationGranted = await requestNotificationPermission();
    print('Notification permission result: $notificationGranted');

    // Then request SMS permission
    // Check current permission status
    print('Checking SMS permission status...');
    final status = await Permission.sms.status;
    print('Current SMS status: $status');

    // If already granted, no need to ask again
    if (status.isGranted) {
      print('SMS permission already granted');
      return true;
    }

    // If denied permanently, open app settings
    if (status.isPermanentlyDenied) {
      print('SMS permission permanently denied. Opening settings...');
      await openAppSettings();
      return false;
    }

    // If not determined or denied, request permission
    if (status.isDenied || !status.isGranted) {
      print('Requesting SMS permission...');
      final result = await Permission.sms.request();
      print('SMS permission request result: $result');

      if (result.isGranted) {
        print('SMS permission granted');
        print(
          '================================================================',
        );
        return true;
      } else if (result.isPermanentlyDenied) {
        print('SMS permission permanently denied');
        print(
          '================================================================',
        );
        await openAppSettings();
        return false;
      } else {
        print('SMS permission denied');
        print(
          '================================================================',
        );
        return false;
      }
    }

    print('SMS permission check completed with unexpected status');
    print('================================================================');
    return false;
  }

  /// Check if SMS permission is granted
  static Future<bool> isSmsPermissionGranted() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// Request notification permission (required for Android 13+)
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestNotificationPermission() async {
    print(
      '==================== REQUESTING NOTIFICATION PERMISSION ====================',
    );

    // Check current permission status
    final status = await Permission.notification.status;
    print('Current notification status: $status');

    // If already granted, no need to ask again
    if (status.isGranted) {
      print('Notification permission already granted');
      return true;
    }

    // If denied permanently, open app settings
    if (status.isPermanentlyDenied) {
      print('Notification permission permanently denied. Opening settings...');
      await openAppSettings();
      return false;
    }

    // If not determined or denied, request permission
    if (status.isDenied || !status.isGranted) {
      print('Requesting notification permission...');
      final result = await Permission.notification.request();
      print('Notification permission request result: $result');

      if (result.isGranted) {
        print('Notification permission granted');
        print(
          '================================================================',
        );
        return true;
      } else if (result.isPermanentlyDenied) {
        print('Notification permission permanently denied');
        print(
          '================================================================',
        );
        await openAppSettings();
        return false;
      } else {
        print('Notification permission denied');
        print(
          '================================================================',
        );
        return false;
      }
    }

    print('Notification permission check completed with unexpected status');
    print('================================================================');
    return false;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
