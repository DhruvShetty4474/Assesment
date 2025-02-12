import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../Notification/notification.dart';


//Websocket Client which connect with Server and main connection with MongoDB...
class WebsocketClient extends StatefulWidget {
  const WebsocketClient({super.key});

  @override
  State<WebsocketClient> createState() => _WebsocketClientState();
}

class _WebsocketClientState extends State<WebsocketClient> {
  late WebSocketChannel channel;
  late ValueNotifier<List<Map<String, dynamic>>> dataNotifier;

  // Initialize the data notifier, connect to the WebSocket server, and start the background service
  @override
  void initState() {
    super.initState();
    dataNotifier = ValueNotifier([]);
    // backgroundService();
    connectWebSocket();
  }

  // // //Make the connection work in the background.
  // void backgroundService() {
  //   FlutterBackgroundService().on('startWebSocket').listen((event) {
  //     connectWebSocket();
  //   });
  // }
// connects to the WebSocket server
  void connectWebSocket({int retryDelay = 3}) {
    channel = IOWebSocketChannel.connect("ws://192.168.29.220:8080");

    // Listen for incoming data
    channel.stream.listen(
            (message){
          // print(" Received data: $message"); // Debug incoming data
          handleIncomingData(message);
        },
        onDone: () {
          print(" WebSocket closed, reconnecting...");
          Future.delayed(Duration(seconds: retryDelay), () {
            connectWebSocket(retryDelay: retryDelay * 2);
          });
        }, onError: (error) {
      print("️ WebSocket error: $error");
      Future.delayed(Duration(seconds: retryDelay), () {
        connectWebSocket(retryDelay: retryDelay * 2);
      });
    });
  }

// handles the incoming data from the server as per insert, update and delete.
  void handleIncomingData(String message) {
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
          AlarmService().showAlarmNotification(
              title: "Data Inserted",
              body: "Data with ID ${decodedData['data']['name']} has been inserted."
          );
          break;

        default:
          print(" Invalid operation: ${decodedData['operation']}");
          return;

      }
      // Update the data notifier
      dataNotifier.value = newDataList;

      // Notify listeners
      dataNotifier.notifyListeners(); // Update UI
    } catch (e) {
      print(" Error processing data: $e");
    }
  }

  // Closes the WebSocket connection
  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

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