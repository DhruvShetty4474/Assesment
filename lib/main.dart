import 'package:flutter/material.dart';

import 'BE/Notification/notification.dart';
import 'BE/Server/websocket.dart';
import 'FE/Pages/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //creating instance of WebsocketServer
  final test = await WebsocketServer();
  //starting the server
  await test.start();

  //initialize notifications...
  await Notification_Service().initNotification();

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

