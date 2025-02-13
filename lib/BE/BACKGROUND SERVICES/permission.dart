// import 'dart:io';
// import 'package:permission_handler/permission_handler.dart';
//
// Future<void> requestBatteryOptimization() async {
//   if (Platform.isAndroid) {
//     final status = await Permission.ignoreBatteryOptimizations.request();
//     if (status.isDenied) {
//       print("Battery optimization permission denied.");
//     } else if (status.isGranted) {
//       print("Battery optimization permission granted.");
//     }
//   }
// }
// Future<void> requestNotificationPermission() async {
//   if (Platform.isAndroid) {
//     var status = await Permission.notification.request();
//     if (status.isDenied || status.isPermanentlyDenied) {
//       print("Notification permission denied!");
//       return;
//     }
//   }
// }
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';

class PermissionHandler {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Check Android version
  static Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  // Handle battery optimization permission
  static Future<void> requestBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    final status = await Permission.ignoreBatteryOptimizations.status;

    if (status.isDenied) {
      final result = await Permission.ignoreBatteryOptimizations.request();

      if (result.isDenied || result.isPermanentlyDenied) {
        // Open battery optimization settings
        try {
          final androidVersion = await _getAndroidVersion();

          if (androidVersion >= 23) { // Android 6.0 or higher
            await openAppSettings();
          }
        } catch (e) {
          print('Error opening battery settings: $e');
        }
      }
    }
  }

  // Handle notification permission
  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 33) { // Android 13 or higher
        // Use the standard permission request
        final status = await Permission.notification.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          print("Notification permission denied for Android 13+");
        }
      } else {
        // For Android 12 and below, direct to app notification settings
        final status = await Permission.notification.status;

        if (status.isDenied || status.isPermanentlyDenied) {
          await AppSettings.openAppSettings(
            type: AppSettingsType.notification,
          );
        }
      }
    } catch (e) {
      print('Error handling notification permission: $e');
    }
  }

  // Check if all required permissions are granted
  static Future<bool> checkAllPermissions() async {
    if (!Platform.isAndroid) return true;

    final notificationStatus = await Permission.notification.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    return notificationStatus.isGranted && batteryStatus.isGranted;
  }
}