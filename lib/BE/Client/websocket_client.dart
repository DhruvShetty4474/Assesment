import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketClient extends StatefulWidget {
  @override
  State<WebsocketClient> createState() => _WebsocketClientState();
}

class _WebsocketClientState extends State<WebsocketClient> {
  late WebSocketChannel channel;
  List<Map<String, dynamic>> messages = []; // Store MongoDB data

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() async {
    channel = IOWebSocketChannel.connect("ws://localhost:8080");

    channel.stream.listen((message) {
      setState(() {
        var decodedData = jsonDecode(message);

        // If data is a list (initial fetch), replace existing data
        if (decodedData is List) {
          messages = decodedData.cast<Map<String, dynamic>>();
        }
        // If it's a single update, add it to the list
        else if (decodedData is Map<String, dynamic>) {
          messages.add(decodedData);
        }
      });
      print("📥 Received data: $message");
    }, onDone: () {
      print("❌ WebSocket closed, reconnecting...");
      Future.delayed(Duration(seconds: 3), connectWebSocket);
    }, onError: (error) {
      print("⚠️ WebSocket error: $error");
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index){
        var item = messages[index];
        return ListTile(
          title: Text(item['name'] ?? 'No Name'), // Adjust according to DB schema
          subtitle: Text("ID: ${item['_id']}"),
        );
      }
    );
  }
}
