import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // await requestNotificationPermission();

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

//CURRENTLY NOT IN USE....
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();

  factory AlarmService() {
    return _instance;
  }

  AlarmService._internal();

  final alarmNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer audioPlayer = AudioPlayer(); // Use audioplayers AudioPlayer
  bool _isInitialized = false;
  bool _alarmIsRunning = false;
  bool _stopRequested = false;

  bool get isInitialized => _isInitialized;
  bool get alarmIsRunning => _alarmIsRunning;
  bool get stopRequested => _stopRequested;

  // **Load alarm state from SharedPreferences**
  Future<void> loadAlarmState() async {
    final prefs = await SharedPreferences.getInstance();
    _alarmIsRunning = prefs.getBool('alarmIsRunning') ?? false;
  }

  // **Save alarm state to SharedPreferences**
  Future<void> _saveAlarmState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarmIsRunning', state);
  }

  // Initialize alarm notifications
  Future<void> initAlarmNotifications() async {
    if (_isInitialized) return;
    await loadAlarmState(); // Load the previous alarm state


    // Prepare Android initialization settings
    const AndroidInitializationSettings initSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    // Initializing the plugin
    await alarmNotificationsPlugin.initialize(initSettings,
        onDidReceiveBackgroundNotificationResponse: notificationBackground,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print("Notification clicked action id: ${response.actionId}");
          print("Notification clicked id: ${response.id}");
          if (response.actionId == 'stop_alarm' && !_stopRequested) {

            print("Close Alarm button clicked");
            stopAlarm(response.id ?? 0);
            // _stopRequested = false;
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
        ongoing: true, // Prevents the notification from being swiped away
        autoCancel: false, // Keeps notification visible until action is taken
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_alarm',
            'Close Alarm',
            showsUserInterface: true,
            cancelNotification: true,
            allowGeneratedReplies: true,
          ),
        ],
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
    );
  }

  // Add this method to handle background notifications
  @pragma('vm:entry-point')
  static void notificationBackground(NotificationResponse response) async {
    if (response.actionId == 'stop_alarm') {
      final instance = AlarmService();
      await instance.initAlarmNotifications(); // Reinitialize if needed
      await instance.stopAlarm(response.id ?? 0);
    }
  }

  // Show notification
  Future<void> showAlarmNotification({int? id, String? title, String? body}) async {
    if (!_isInitialized) await initAlarmNotifications();
    if (_alarmIsRunning) return; // Prevent multiple alarms

    _alarmIsRunning = true;
    _stopRequested = false; //reset the flag
    await _saveAlarmState(true); // Save state

    try {
      if (audioPlayer.state == PlayerState.playing) {
        await audioPlayer.stop();  // Stop any currently playing sound
      }
      // Load and play alarm sound in loop using audioplayers
      audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('notifi_alrm_sound.mp3'));
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
    try {
      print("Stopping alarm for notification ID: $notificationId");
      _alarmIsRunning = false;
      _stopRequested = true;
      await _saveAlarmState(false); // Save stat
      if (audioPlayer.state == PlayerState.playing) {
        await audioPlayer.stop();
      }
      // await _audioPlayer.dispose(); // Dispose audio player after use

      // Cancel the notification
      await alarmNotificationsPlugin.cancel(notificationId);
      print("Alarm stopped successfully!");
    } catch (e) {
      print('Error stopping alarm: $e');
      _stopRequested = false;
      _alarmIsRunning = true;
      await _saveAlarmState(true);
    }
  }
}


class Alarm_Notification_Service2 {
  final FlutterLocalNotificationsPlugin notificationPlugin =
  FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return; // Prevent multiple initializations

    // Prepare Android initialization settings
    const AndroidInitializationSettings initSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings
    const InitializationSettings initSettings = InitializationSettings(
      android: initSettingsAndroid,
    );

    // Initialize the plugin and handle actions
    await notificationPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'stop_alarm') {
          stopAlarm();
        }
      },
    );

    _isInitialized = true; // Mark initialized
  }

  // NOTIFICATION DETAIL SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_service_id',
        'alarm_service_channel',
        channelDescription: 'Alarm notification channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alrmsound'),
        ongoing: true, // Prevents the notification from being swiped away
        autoCancel: false, // Keeps notification visible until action is taken
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_alarm',
            'Close Alarm',
            showsUserInterface: true,
            cancelNotification: true,
            allowGeneratedReplies: true,
          ),
        ],
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({int? id, String? title, String? body}) async {
    int uniqueId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    return notificationPlugin.show(
      uniqueId, // Unique notification ID
      title,
      body,
      notificationDetails(),
    );
  }


  void stopAlarm() async {
    print("Stopping Alarm Sound...");
    await _audioPlayer.stop();
    notificationPlugin.cancelAll();
  }
}

