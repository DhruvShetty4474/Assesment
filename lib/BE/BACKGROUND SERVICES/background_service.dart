import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:filamentai/BE/Client/websocket_client2.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
      print(" Background service is already running.");
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

// Future<void> startClient() async {
//   if (isClientConnected.value) {
//     print("WebSocket client is already connected");
//     return; // Prevent duplicate connections
//   }
//
//   client.value = WClient(); // Assign singleton instance
//   await client.value!.connectWebSocket();
//   // isClientConnected.value = true;
//   print("Background WebSocket client started");
// }

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {



  // WClient _client; // Create a single WebSocket client instance
  // bool _isClientConnected = false; // Track client connection state

  // client.value ??= WClient();

  //Function to start the websocket client

// Add a small delay to avoid race condition with UI initialization
  await Future.delayed(const Duration(milliseconds: 500));
  // // Then check if we need to connect
  // if (!isClientConnected.value && client.value == null) {
  //   print('Background service initializing connection');
  //   client.value = WClient();
  //   await client.value!.connectWebSocket();
  //   isClientConnected.value = true;
  // }

    if (service is AndroidServiceInstance) {

    // // Periodic check to ensure connection
    // Timer.periodic(const Duration(minutes: 1), (timer) async {
    //   if (!isClientConnected.value) {
    //     print('Periodic connection check - attempting to reconnect');
    //     await client.value?.connectWebSocket();
    //   }
    // });

      service.setAsForegroundService();

      ///

      // Set a persistent notification
      service.setForegroundNotificationInfo(
        title: "App is running in background",
        content: "Maintaining connection",
      );

    service.on('setAsForeground').listen((event) {

      print('foreground started ');

      if (isClientConnected.value == false) {
        client.value.disconnectWebSocket();
         Future.delayed(const Duration(milliseconds: 500));
        client.value.connectWebSocket();
      }
    });


    service.on('setAsBackground').listen((event) {

      print('background started ');

      if (isClientConnected.value ==  false) {
        client.value.disconnectWebSocket();
        Future.delayed(const Duration(milliseconds: 500));
        client.value.connectWebSocket();
      }
    });


    service.on('stopService').listen((event) {
      isClientConnected.value = false;
      client.value.disconnectWebSocket();
      service.stopSelf();
    });
  }


  /// secnd
  // try {
  //   // client.value ??= WClient();
  // if (isClientConnected.value == false || client.value == null) {
  // print('Background service initializing connection');
  // await client.value?.connectWebSocket();
  // isClientConnected.value = true;
  // }
  // } catch (e) {
  // print('Initial connection error: $e');
  // }

}
