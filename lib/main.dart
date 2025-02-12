import 'package:flutter/material.dart';

import 'BE/BACKGROUND SERVICES/background_service.dart';
import 'BE/BACKGROUND SERVICES/foreground.dart';
import 'BE/BACKGROUND SERVICES/permission.dart';
import 'BE/Client/websocket_client2.dart';
import 'BE/Notification/notification.dart';
import 'BE/Server/websocket.dart';
import 'FE/Pages/home.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //initialize notifications...
  await Notification_Service().initNotification();

  //initialize alarm notifications
  await AlarmService().initAlarmNotifications();

  //request battery optimization
  await requestBatteryOptimization();

  //request notification permission
  await requestNotificationPermission();

  BackgroundService backgroundService = BackgroundService();
  await backgroundService.initializeService();

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

