
// import 'package:flutter_background_service/flutter_background_service.dart';
//
// import '../Client/websocket_client.dart';
//
// Future<void> initializeServices() async{
//   final service = FlutterBackgroundService();
//
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true
//     ), iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onBackground
//     )
//   );
//   service.startService();
// }
//
//
// void onStart(ServiceInstance service) {
//
//
//   service.on('stop').listen((event) {
//     service.stopSelf();
//   });
// }