import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../BACKGROUND SERVICES/background_service.dart';
import '../Notification/notification.dart';

 ValueNotifier<List<Map<String, dynamic>>> dataNotifier = ValueNotifier([]);

 ValueNotifier<bool> isClientConnected = ValueNotifier(false);

 ValueNotifier<WClient> client = ValueNotifier(WClient());



//Websocket Client which connect with Server and main connection with MongoDB...
class WebsocketClientUI extends StatefulWidget {
  const WebsocketClientUI({super.key});

  @override
  State<WebsocketClientUI> createState() => _WebsocketClientUIState();
}

class _WebsocketClientUIState extends State<WebsocketClientUI> with WidgetsBindingObserver {
  final BackgroundService _backgroundService = BackgroundService();


  // Initialize the data notifier, connect to the WebSocket server, and start the background service
  @override
  void initState() {
    super.initState();


    // Connect if not connected
    if (!isClientConnected.value) {
      client.value.connectWebSocket();
      isClientConnected.value = true;
    }
    // _backgroundService.initializeService();

    //initialize foreground service

    WidgetsBinding.instance.addObserver(this);

  }

  // void clientconnection(){
  //   if (isClientConnected.value) {
  //     print('Client already connected');
  //     return;
  //   }
  //   try{
  //     // Initialize the WebSocket client
  //      client.value = WClient();
  //      client.value!.connectWebSocket();
  //      isClientConnected.value = true;
  //   }
  //   catch(e){
  //     print('WebSocket connection failed: $e');
  //     isClientConnected.value = false; // Ensure the state is correct
  //   }
  //
  // }

  ///test
  // void clientconnection() {
  //   client.value ??= WClient();
  //
  //   if (!isClientConnected.value) {
  //     client.value!.connectWebSocket();
  //   } else {
  //     print("Client already connected");
  //   }
  // }
  /// Make the connection work in the background.
  // void backgroundService() {
  //   FlutterBackgroundService().on('startWebSocket').listen((event) {
  //     connectWebSocket();
  //   });
  // }
// connects to the WebSocket server

  ///hello
  ///
  // // connecting the app to the websocket server
//   void connectWebSocket() {
//     channel = IOWebSocketChannel.connect("ws://localhost:8080");
//
//     // Listen for incoming data
//     channel.stream.listen(
//             (message){
//           // print(" Received data: $message"); // Debug incoming data
//           handleIncomingData(message);
//         },
//        onDone: () {
//       print(" WebSocket closed, reconnecting...");
//       Future.delayed(const Duration(seconds: 3), connectWebSocket);
//     }, onError: (error) {
//       print("️ WebSocket error: $error");
//     });
//   }
//
// // handles the incoming data from the server as per insert, update and delete.
//   void handleIncomingData(String message) {
//     try{
//       // Decode the incoming data as JSON
//       var decodedData = jsonDecode(message);
//
//       // Check if the decoded data is a list
//       if (decodedData is List){
//         dataNotifier.value = decodedData.cast<Map<String, dynamic>>();
//         dataNotifier.notifyListeners();
//         return;
//       }
//
//       // Check if the decoded data is a map
//       if (decodedData is! Map<String, dynamic> || !decodedData.containsKey('operation')) {
//         print(" Invalid data format: $decodedData");
//         return;
//       }
//       // Convert _id to string
//       if (decodedData['_id'] != null) {
//         decodedData['_id'] = decodedData['_id'].toString();
//       }
//       // Work on a new list to avoid modifying `dataNotifier.value` directly
//       List<Map<String, dynamic>> newDataList = List.from(dataNotifier.value);
//
//       // Process the incoming data based on the operation type and perform the corresponding action
//       switch (decodedData['operation']) {
//         case 'delete':
//           //Currently only showing the document id will show the name of the user that was deleted..
//           Notification_Service().showNotification(title: "Data Deleted", body: "Data with ID ${decodedData['document_id']} has been deleted.");
//           newDataList.removeWhere((item) => item['_id'] == decodedData['document_id']);
//           break;
//         case 'update':
//           if (decodedData.containsKey('data')) {
//             Map<String, dynamic> updatedData = decodedData['data']; // Extract actual data
//             int index = newDataList.indexWhere((item) => item['_id'] == updatedData['_id']);
//
//             if (index != -1) {
//               newDataList[index] = updatedData; // Replace old data with new one
//             }
//           }
//           Notification_Service().showNotification(title: "Data Updated", body: "Data with ID ${decodedData['data']['name']} has been updated.");
//           break;
//
//         case 'insert':
//           newDataList.add(decodedData['data']);
//           // Show alarm notification
//           AlarmService().showAlarmNotification(
//               title: "Data Inserted",
//               body: "Data with ID ${decodedData['data']['name']} has been inserted."
//           );
//           break;
//
//         default:
//           print(" Invalid operation: ${decodedData['operation']}");
//           return;
//
//       }
//       // Update the data notifier
//       dataNotifier.value = newDataList;
//
//       // Notify listeners
//       dataNotifier.notifyListeners(); // Update UI
//     } catch (e) {
//       print(" Error processing data: $e");
//     }
//     }

  // Closes the WebSocket connection

  // Closes the WebSocket connection and disposes of resources
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // client.value?.disconnectWebSocket();
    super.dispose();
  }


  // Checking the app state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {

      print("App is in Foreground");
      _backgroundService.setForeground(); // Switch to foreground mode
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {

      print("App is in Background");
      _backgroundService.setBackground(); // Switch to background mode
    }
  }

  //shows the data from the database
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: dataNotifier,
        builder: (context, dataList, child) {
          return ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index){
                var item = dataList[index];
                if (item['_id'] == null) return const SizedBox();
                return ListTile(
                  title: Text(item['name'] ?? 'No Name'), // Adjust according to DB schema
                  subtitle: Text("ID: ${item['_id']}"),
                );
              }
          );
        }
    );
  }
}


class WClient {
  static final WClient _instance = WClient._internal();
  factory WClient() => _instance;
  WClient._internal();

   WebSocketChannel? channel;
  bool isConnecting = false;

  Future <void> connectWebSocket() async {
    if (isClientConnected.value || isConnecting || channel != null) return;

    isConnecting = true;
    try{
      channel =  IOWebSocketChannel.connect("ws://192.168.29.220:8080",);
      // Listen for incoming data
      await channel!.stream.listen(
            (message){
          // print(" Received data: $message"); // Debug incoming data
          handleIncomingData(message);
        },
        onDone: () {
          print(" WebSocket closed, reconnecting...");
          isClientConnected.value = false;
          isConnecting = false;
          channel = null;
          Future.delayed(const Duration(seconds: 3), connectWebSocket);
        }, onError: (error) {
              print("WebSocket error: $error");
              isClientConnected.value = false;
              isConnecting = false;
              channel = null;
              Future.delayed(const Duration(seconds: 3), connectWebSocket);
            }
      );
      isClientConnected.value = true; // Ensure flag is updated

    }catch (e) {
      print("Error connecting WebSocket: $e");
      isClientConnected.value = false;
      isConnecting = false;
      channel = null;
      Future.delayed(const Duration(seconds: 3), connectWebSocket);    }
  }

  void handleIncomingData(String message) {
    bool isAppForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    try{
      // Decode the incoming data as JSON
      var decodedData = jsonDecode(message);

      // Check if the decoded data is a list
      if (decodedData is List){
        dataNotifier.value = decodedData.cast<Map<String, dynamic>>();
        dataNotifier.notifyListeners();
        return;
      }

      // Check if the decoded data is a map
      if (decodedData is! Map<String, dynamic> || !decodedData.containsKey('operation')) {
        print(" Invalid data format: $decodedData");
        return;
      }
      // Convert _id to string
      if (decodedData['_id'] != null) {
        decodedData['_id'] = decodedData['_id'].toString();
      }
      // Work on a new list to avoid modifying `dataNotifier.value` directly
      List<Map<String, dynamic>> newDataList = List.from(dataNotifier.value);

      // Process the incoming data based on the operation type and perform the corresponding action
      switch (decodedData['operation']) {
        case 'delete':
        //Currently only showing the document id will show the name of the user that was deleted..
          Notification_Service().showNotification(title: "Data Deleted", body: "Data with ID ${decodedData['document_id']} has been deleted.");
          newDataList.removeWhere((item) => item['_id'] == decodedData['document_id']);
          break;
        case 'update':
          if (decodedData.containsKey('data')) {
            Map<String, dynamic> updatedData = decodedData['data']; // Extract actual data
            int index = newDataList.indexWhere((item) => item['_id'] == updatedData['_id']);

            if (index != -1) {
              newDataList[index] = updatedData; // Replace old data with new one
            }
          }
          Notification_Service().showNotification(title: "Data Updated", body: "Data with ID ${decodedData['data']['name']} has been updated.");
          break;

        case 'insert':
          newDataList.add(decodedData['data']);
          // Show alarm notification
          // AlarmService().showAlarmNotification(
          //     title: "Data Inserted",
          //     body: "Data with ID ${decodedData['data']['name']} has been inserted."
          // );
          Alarm_Notification_Service2().showNotification(
                title: "Data Inserted",
                body: "Data with ID ${decodedData['data']['name']} has been inserted."
            );
          break;

        default:
          print(" Invalid operation: ${decodedData['operation']}");
          return;
      }
// Only update UI if app is in foreground
      if (isAppForeground) {
        dataNotifier.value = newDataList;
        dataNotifier.notifyListeners();
      } else {
        print("⚠️ App is in background/killed, skipping UI update but triggering notifications.");

      }
    } catch (e) {
      print(" Error processing data: $e");
    }
  }

  void disconnectWebSocket() {
    if (isClientConnected.value) {
      channel!.sink.close();
      isClientConnected.value = false;
      isConnecting = false;
      channel = null;
    }
  }

}