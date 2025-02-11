import 'package:flutter/material.dart';

import 'BE/BACKGROUND SERVICES/foreground.dart';
import 'BE/BACKGROUND SERVICES/permission.dart';
import 'BE/Notification/notification.dart';
import 'BE/Server/websocket.dart';
import 'FE/Pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //creating instance of WebsocketServer
  WebsocketServer _server = WebsocketServer();
  //starting the server
  await _server.start();

  //initialize notifications...
  await Notification_Service().initNotification();

  //initialize alarm notifications
  await AlarmService().initAlarmNotifications();

  //request battery optimization
  await requestBatteryOptimization();

  // //initialize foreground service
  // await  ForegroundService().initializeService();

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

