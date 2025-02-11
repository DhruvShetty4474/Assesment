//
// // import 'package:flutter_foreground_task/flutter_foreground_task.dart';import 'dart:async';
//
//
// import 'dart:async';
//
// import 'package:filamentai/BE/Client/websocket_client.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import '../Server/websocket.dart';
//
// class ForegroundService {
//   static final ForegroundService _instance = ForegroundService._internal();
//   factory ForegroundService() => _instance;
//   ForegroundService._internal();
//   final service = FlutterBackgroundService();
//
//   bool _isRunning = false;
//
//
//   ///Start the foreground Services
//   Future<void> initializeService() async {
//     if(_isRunning) return;
//
//     _isRunning = true;
//
//     await service.configure(
//         iosConfiguration: IosConfiguration(),
//         androidConfiguration: AndroidConfiguration(
//             onStart: onStart,
//             isForegroundMode: true,
//             autoStart: true,
//             autoStartOnBoot: true,
//         )
//     );
//
//     service.startService(); // Start the service
//
//   }
//
//
//
//   void setForeground() async {
//      service.invoke('setAsForeground');
//   }
//
//   void setBackground() async {
//      service.invoke('setAsBackground');
//   }
//
//   void stopService() async {
//      service.invoke('stopService');
//   }
//
//
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   WebsocketServer _server = WebsocketServer();
//   bool _isServerRunning = false;  // Track server state
//   bool _isClientConnected = false; // Track client connection state
//   WClient _client = WClient(); // Create a single WebSocket client instance
//
//   // Start WebSocket server only if not running
//   Future<void> startServer() async {
//     if (!_isServerRunning) {
//       print('Starting WebSocket server...');
//       await _server.start();
//       _isServerRunning = true;
//       print('WebSocket server started.');
//     }
//   }
//
//   // Function to start WebSocket client only if it's not already connected
//   Future<void> startClient() async {
//     if (!_isClientConnected) {
//       print('Checking WebSocket client connection...');
//       await Future.delayed(Duration(seconds: 2)); // Small delay to prevent duplicates
//       _client.connectWebSocket();
//       _isClientConnected = true;
//       print('WebSocket client connected.');
//     }
//   }
//
//   Future<void> maintainConnection() async {
//     while (true) {
//       await Future.delayed(Duration(seconds: 5));
//       if (!_isServerRunning) {
//         print('Restarting WebSocket server...');
//         await startServer();
//       }
//       if (!_isClientConnected) {
//         print('Reconnecting WebSocket client...');
//         await startClient();
//       }
//     }
//   }
//
//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) async {
//       print('Switching to foreground...');
//       await Future.delayed(Duration(seconds: 1));
//       await startServer();
//       await startClient();
//       print(' connected  in foreground.');
//     });
//
//     service.on('setAsBackground').listen((event) async {
//       ///wanna class the connectWebSocket function in this
//       print('Switching to background...');
//       await Future.delayed(Duration(seconds: 1));
//       await startServer();
//       await startClient();
//       print('connected in background.');
//       // Timer.periodic(const Duration(seconds: 1), (timer) async {
//       //   print("background");
//       //       });
//     });
//   }
//   service.on('stopService').listen((event) async {
//     service.stopSelf();
//     _isServerRunning = false;
//     _isClientConnected = false;
//   });
//   maintainConnection();
// }