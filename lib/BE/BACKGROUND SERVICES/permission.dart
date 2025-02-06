import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBatteryOptimization() async {
  if (Platform.isAndroid) {
    final status = await Permission.ignoreBatteryOptimizations.request();
    if (status.isDenied) {
      print("Battery optimization permission denied.");
    } else if (status.isGranted) {
      print("Battery optimization permission granted.");
    }
  }
}


Future<void> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      print("Notification permission denied!");
      return;
    }
  }
}