import 'package:flutter/material.dart';

import 'BE/BACKGROUND SERVICES/background_service.dart';
import 'BE/BACKGROUND SERVICES/permission.dart';
import 'BE/Client/websocket_client2.dart';
import 'BE/Notification/notification.dart';
import 'FE/Pages/home.dart';

ValueNotifier<WClient> client = ValueNotifier(WClient());



@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // First check if permissions are already granted
  if (!(await PermissionHandler.checkAllPermissions())) {
    // Request permissions only if not already granted
    await PermissionHandler.requestBatteryOptimization();
    await PermissionHandler.requestNotificationPermission();

    // Check again after requests
    if (!(await PermissionHandler.checkAllPermissions())) {
      // You might want to show a dialog here explaining that permissions are required
      print("Required permissions not granted");
      // Optionally show a dialog to user explaining why permissions are needed
    }
  }

  //initialize notifications...
  await Notification_Service().initNotification();

  //initialize alarm notifications
  await AlarmService().initAlarmNotifications();


  BackgroundService backgroundService = BackgroundService();
    // if (!await backgroundService.service.isRunning()) {
    //   await backgroundService.initializeService();
    // } else{
    //   print("Background service already running.");
    // }


  if (await backgroundService.service.isRunning()) {
    print("Stopping background service...");
    backgroundService.stopService();

    // Wait for a short delay to ensure the service is stopped completely
    await Future.delayed(Duration(seconds: 2));

    print("Restarting background service...");
    await backgroundService.initializeService();
    await initializeClient();
  } else {
    print("Background service not running. Starting...");
    await backgroundService.initializeService();
    await initializeClient();
  }





  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}


Future<void> initializeClient() async {
  if (!isClientConnected.value) {
    print(" Initializing WebSocket...");
    // WClient is already singleton, no need to reassign
    await client.value.connectWebSocket();
  } else {
    print("WebSocket already connected");
  }
}
