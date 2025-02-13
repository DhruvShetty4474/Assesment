import 'dart:async';

import 'package:filamentai/BE/Client/websocket_client2.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../main.dart';
import '../Notification/notification.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();

  factory BackgroundService() => _instance;
  BackgroundService._internal();

  //creating the instance for background service package...
  final service = FlutterBackgroundService();
  AlarmService? _alarmService;

  Future<void> initializeService() async {
     // Load the alarm state when service starts

    if (await service.isRunning()) {
      print("Background service is already running.");
      return;
    }
    _alarmService = AlarmService();
    await _alarmService!.loadAlarmState();

    // platform basis configuration
    await service.configure(
        iosConfiguration: IosConfiguration(),
        androidConfiguration: AndroidConfiguration(
          onStart: onStart, // what should be performed when started
          isForegroundMode: true, // set to true if you want to show a notification
          autoStart: true, // set to true if you want to start the service when the app starts
          autoStartOnBoot: true, // set to true if you want to start the service when the device boots
          foregroundServiceTypes: [
            AndroidForegroundType.dataSync,
            AndroidForegroundType.mediaPlayback
          ],
          foregroundServiceNotificationId: 888, // Add this
          initialNotificationTitle: "App is running in background",
          initialNotificationContent: "Maintaining connection",
        )
    );

    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  void setForeground() async {
    service.invoke('setAsForeground');
  }

  void setBackground() async {
    service.invoke('setAsBackground');
  }

  void stopService() async {
    service.invoke('stopService');
  }
}
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {

  print("disconnecting the client from background service");
  client.value.disconnectWebSocket();

  await Future.delayed(const Duration(milliseconds: 500));

    if (service is AndroidServiceInstance) {

      service.setAsForegroundService();
      // Set a persistent notification
      service.setForegroundNotificationInfo(
        title: "App is running in background",
        content: "Maintaining connection",
      );

      service.on('setAsForeground').listen((event) {
        print('Foreground mode activated');
        // Don't create new connection if one exists
        if (!isClientConnected.value && client.value.channel == null) {
          print("Initiating foreground connection");
          client.value.connectWebSocket();
          isClientConnected.value = true;
        }
      });

      service.on('setAsBackground').listen((event) {
        print('Background mode activated');
        // Don't create new connection if one exists
        if (!isClientConnected.value && client.value.channel == null) {
          print("Initiating background connection");
          client.value.connectWebSocket();
          isClientConnected.value = true;
        }
      });


    service.on('stopService').listen((event) {
      print("Service stop requested");
      client.value.disconnectWebSocket();
      service.stopSelf();
    });
  }
}
