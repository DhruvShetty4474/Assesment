import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../BACKGROUND SERVICES/permission.dart';

///Local Notification not a UI pop up

/// Currently only available for android

class Notification_Service {
  final notification_pulign = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  //INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return; //prevent multiple initialization

    //Ask for Notification permission
    await requestNotificationPermission();

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


class AlarmService {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() {
    return _instance;
  }

  AlarmService._internal();

  final alarmNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer(); // Use audioplayers AudioPlayer
  bool _isInitialized = false;
  bool _alarmIsRunning = false;
  bool _stopRequested = false;

  bool get isInitialized => _isInitialized;
  bool get alarmIsRunning => _alarmIsRunning;
  bool get stopRequested => _stopRequested;

  // Initialize alarm notifications
  Future<void> initAlarmNotifications() async {
    if (_isInitialized) return;

    await requestNotificationPermission();

    // Prepare Android initialization settings
    const AndroidInitializationSettings initSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    // Initializing the plugin
    await alarmNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print("Notification clicked action id: ${response.actionId}");
          print("Notification clicked id: ${response.id}");
          if (response.actionId == 'stop_alarm') {
            print("Close Alarm button clicked");
            stopAlarm(response.id ?? 0);
          }
        });
    _isInitialized = true; // Set initialized flag
  }

  // Notification details setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_notification_channel',
        'Alarm Notification',
        channelDescription: 'Notification test channel_description',
        importance: Importance.max,
        priority: Priority.high,
       playSound: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_alarm',
            'Close Alarm',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
    );
  }

  // Show notification
  Future<void> showAlarmNotification({int? id, String? title, String? body}) async {
    if (!_isInitialized) await initAlarmNotifications();
    if (_alarmIsRunning) return; // Prevent multiple alarms

    _alarmIsRunning = true;

    try {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();  // Stop any currently playing sound
      }
      // Load and play alarm sound in loop using audioplayers
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('notifi_alrm_sound.mp3'));
 // Set loop mode to loop forever
    } catch (e) {
      print("Error playing alarm sound: $e");
    }

    print("Attempting to show notification...");
    // Generate a random id for the notification
    int uniqueId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await alarmNotificationsPlugin.show(
      uniqueId, // Unique notification ID
      title,
      body,
      notificationDetails(),
      payload: 'stop_alarm',
    ).then((value) {
      print("Notification triggered successfully");
    }).catchError((e) {
      print("Error triggering notification: $e");
    });

    // Automatically stop the alarm after 1 minute if not manually stopped
    Future.delayed(const Duration(minutes: 1), () async {
      if (!_stopRequested) {
        stopAlarm(uniqueId);
        print('1 min over, alarm stopped automatically');
      }
    });
  }

  // Stop alarm and cancel notification
  Future<void> stopAlarm(int notificationId) async {
    if (!_alarmIsRunning) return;

    _alarmIsRunning = false;
    _stopRequested = true;

    try {
      print("Stopping alarm for notification ID: $notificationId");

      // Stop the audio playback
      await _audioPlayer.stop();
      await _audioPlayer.dispose(); // Dispose audio player after use

      // Cancel the notification
      await alarmNotificationsPlugin.cancel(notificationId);
      print("Alarm stopped successfully!");
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }
}







