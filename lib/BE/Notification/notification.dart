import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Currently only available for android

class Notification_Service {
  final notification_pulign = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  //INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return; //prevent multiple initialization

    if (Platform.isAndroid) {
      // Request permission explicitly on Android 13+
      if (await Permission.notification.request().isDenied) {
        return; // Exit if permission is not granted
      }
    }

    //prepare android init setting
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    //init Settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    //initializing the plugin
    await notification_pulign.initialize(initSettings);

    _isInitialized = true; // Setting initialized flag
  }

  //NOTIFICATION DETAIL SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails('channel_id', 'channel_name',
            channelDescription: 'Notification channel_description',
            importance: Importance.max,
            priority: Priority.high, playSound: true));
  }

  //SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body}) async {
  return notification_pulign.show(id, title, body, notificationDetails());
  }
}
