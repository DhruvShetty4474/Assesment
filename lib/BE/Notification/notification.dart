import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

///Local Notification not a UI pop up

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
            priority: Priority.high,
            playSound: true));
  }

  //SHOW NOTIFICATION
  Future<void> showNotification({int? id, String? title, String? body}) async {
    //Generate a random id
    int uniqueId =
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return notification_pulign.show(
        uniqueId, // Unique notification ID
        title,
        body,
        notificationDetails());
  }
}

class AlarmNotificationService {
  final alarmNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _alarmIsInitialized = false;

  bool _alarmIsRunning = false;

  bool get alarmIsRunning => _alarmIsRunning;

  bool get alarmIsInitialized => _alarmIsInitialized;

  final AudioPlayer audioPlayer = AudioPlayer();

  //INITIALIZE
  Future<void> initAlarmNotifications() async {
    if (_alarmIsInitialized) return; //prevent multiple initialization

    if (Platform.isAndroid) {
      // Request permission explicitly on Android 13+
      if (await Permission.notification.request().isDenied) {
        return; // Exit if permission is not granted
      }
    }
    //prepare android init setting
    const AndroidInitializationSettings alarmAndroidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    //init Settings
    const initSettings = InitializationSettings(
      android: alarmAndroidInitSettings,
    );

    //initializing the plugin
    await alarmNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: ( NotificationResponse response) {
          print("Notification clicked action id: ${response.actionId}");
          print("Notification clicked id : ${response.id}");
          if (response.actionId == 'stop_alarm'){
            print("Close Alarm button clicked"); // Log when button is pressed
            stopAlarm(response.id ?? 0);
      }
    });

    _alarmIsInitialized = true; // Setting initialized flag
  }
  //SHOW NOTIFICATION
  Future<void> showAlarmNotification({
    int? id,
    String? title,
    String? body,
  }) async {
    _alarmIsRunning = false;
    // Start playing the alarm sound
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    await audioPlayer.play(AssetSource('sound.mp3'));

    //show notification with " Stop Alarm " option..
    const AndroidNotificationDetails alarmAndroidDetails =
        AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notification',
      channelDescription: 'Triggered when new data is added',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('sound'),
      playSound: true,
      // category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      actions: <AndroidNotificationAction> [
        AndroidNotificationAction('stop_alarm', 'Close Alarm', showsUserInterface: true,
          cancelNotification: false//cancel notification when clicked
          ,),
      ],
    );

    const NotificationDetails alarmNotificationDetails =
        NotificationDetails(android: alarmAndroidDetails);
    //Generate a random id
    int uniqueId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    //Show notification
    await alarmNotificationsPlugin.show(
      uniqueId, title, body,
      alarmNotificationDetails,
      payload: 'stop_alarm', // Pass payload to identify the action
    );
    // Stop alarm after 1 minute
    Future.delayed(const Duration(minutes: 1), () {
      stopAlarm(uniqueId);
      print('1 min over');
    });
  }

  // Stop alarm and cancel notification
  Future<void> stopAlarm(int notificationId) async {
    if (_alarmIsRunning) return; // Skip if already stopped
    _alarmIsRunning = true;

    try {
      print("Stopping alarm for notification ID: $notificationId");

      if (audioPlayer.state == PlayerState.playing) {
        await audioPlayer.stop();
        await audioPlayer.dispose();
      }


      await alarmNotificationsPlugin.cancel(notificationId);
      print("Alarm stopped successfully!");
      _alarmIsRunning = false;
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }
}





