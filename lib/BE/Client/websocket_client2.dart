import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../main.dart';
import '../BACKGROUND SERVICES/background_service.dart';
import '../Notification/notification.dart';

 ValueNotifier<List<Map<String, dynamic>>> dataNotifier = ValueNotifier([]);

 ValueNotifier<bool> isClientConnected = ValueNotifier(false);

final BackgroundService _backgroundService = BackgroundService();


//Websocket Client which connect with Server and main connection with MongoDB...
class WebsocketClientUI extends StatefulWidget {
  const WebsocketClientUI({super.key});

  @override
  State<WebsocketClientUI> createState() => _WebsocketClientUIState();
}

class _WebsocketClientUIState extends State<WebsocketClientUI> with WidgetsBindingObserver {



  // Initialize the data notifier, connect to the WebSocket server, and start the background service
  @override
  void initState() {
    super.initState();


    // Connect if not connected
    if (!isClientConnected.value) {
      client.value.connectWebSocket();
      isClientConnected.value = true;
    }

    WidgetsBinding.instance.addObserver(this);

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // client.value?.disconnectWebSocket();
    super.dispose();
  }


  // Checking the app state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Lifecycle state changed to: $state");
    if (state == AppLifecycleState.resumed) {
      print("App resuming to foreground");
      // Don't disconnect, just ensure we have one connection
      client.value.disconnectWebSocket();
      _backgroundService.setForeground();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      print("App moving to background");
      client.value.disconnectWebSocket();
      _backgroundService.setBackground();
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
  Timer? reconnectTimer;
  String? connectionId;

  Future <void> connectWebSocket() async {
    if (isClientConnected.value || isConnecting || channel != null) {
      print("Connection attempt blocked - Status: Connected=${isClientConnected.value}, Connecting=${isConnecting}, Channel exists=${channel != null}");
      return;
    }

    isConnecting = true;
    connectionId = DateTime.now().millisecondsSinceEpoch.toString();

    print("Starting new connection attempt - ID: $connectionId");
    try {
      reconnectTimer?.cancel();

      channel = IOWebSocketChannel.connect("ws://192.168.29.220:8080",);
      // Listen for incoming data
      await channel!.stream.listen(
              (message) {
                print("Received message on connection $connectionId");
            // print(" Received data: $message"); // Debug incoming data
            handleIncomingData(message);
          },
          onDone: () {
            print(" WebSocket closed, reconnecting...");
            print("WebSocket closed - ID: $connectionId");
            _handleDisconnection();
          }, onError: (error) {
        print("WebSocket error on ID: $connectionId - $error");
        print("WebSocket error: $error");
        _handleDisconnection();
      }
      );
      isClientConnected.value = true; // Ensure flag is updated
      isConnecting = false;
      print("WebSocket connected successfully - ID: $connectionId");
      print("WebSocket connected successfully");
    } catch (e) {
      print("Connection error on ID: $connectionId - $e");
      print("Error connecting WebSocket: $e");
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    print("🔌 Handling disconnection for ID: $connectionId");
    isClientConnected.value = false;
    isConnecting = false;
    channel = null;
    final currentId = connectionId;
    connectionId = null;

    // Schedule reconnection only if not explicitly disconnected
    reconnectTimer?.cancel();
    reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!isClientConnected.value && currentId == connectionId) {
        print("Attempting reconnect after disconnection");
        client.value.connectWebSocket();
      }
    });
  }

  void disconnectWebSocket() {
    print("Explicitly disconnecting WebSocket - ID: $connectionId");
    reconnectTimer?.cancel();
    if (channel != null) {
      channel!.sink.close();
      channel = null;
    }
    connectionId = null;
    isConnecting = false;
    isClientConnected.value = false;
    print("WebSocket disconnected explicitly");
  }


  void handleIncomingData(String message) {
    bool isAppForeground = WidgetsBinding.instance.lifecycleState ==
        AppLifecycleState.resumed;
    try {
      // Decode the incoming data as JSON
      var decodedData = jsonDecode(message);

      // Check if the decoded data is a list
      if (decodedData is List) {
        dataNotifier.value = decodedData.cast<Map<String, dynamic>>();
        dataNotifier.notifyListeners();
        return;
      }

      // Check if the decoded data is a map
      if (decodedData is! Map<String, dynamic> ||
          !decodedData.containsKey('operation')) {
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
          Notification_Service().showNotification(title: "Data Deleted",
              body: "Data with ID ${decodedData['document_id']} has been deleted.");
          newDataList.removeWhere((item) =>
          item['_id'] == decodedData['document_id']);
          break;
        case 'update':
          if (decodedData.containsKey('data')) {
            Map<String,
                dynamic> updatedData = decodedData['data']; // Extract actual data
            int index = newDataList.indexWhere((item) =>
            item['_id'] == updatedData['_id']);

            if (index != -1) {
              newDataList[index] = updatedData; // Replace old data with new one
            }
          }
          Notification_Service().showNotification(title: "Data Updated",
              body: "Data with ID ${decodedData['data']['name']} has been updated.");
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
        print(
            "App is in background/killed, skipping UI update but triggering notifications.");
      }
    } catch (e) {
      print(" Error processing data: $e");
    }
  }
}