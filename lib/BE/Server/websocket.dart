import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:filamentai/BE/Server/server.dart';
import '../Constant/constant.dart';

//Websocket Server which connect with Client and main connection with MongoDB...
//Websocket Server which connect with Client and main connection with MongoDB...
class WebsocketServer{
  final int port;
  final List<WebSocket> clients = []; // List to store connected clients
  WebsocketServer({this.port = PORT});

  // A function to start the WebSocket server
  Future<void> start() async{
    await MongoDB_Server.connect();

    HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print("WebSocket Server running on ws://localhost:$port");

    server.transform(WebSocketTransformer()).listen((WebSocket socket) async {
      clients.add(socket);
      print("New WebSocket client connected");

      // Send existing data to the new client
      await sendExistingData(socket);

      socket.done.then((_) {
        print("WebSocket client disconnected");
        clients.remove(socket);
      });
    });
    // await MongoDB_Server.watchChanges();
    watchDatabaseChanges();
  }
  Future<void> sendExistingData(WebSocket socket) async {
    var data = await MongoDB_Server.collection.find().toList();
    socket.add(jsonEncode(data)); // Send existing data as JSON
  }

  //used to watch changes in database
  void watchDatabaseChanges() {
    MongoDB_Server.watchChanges().listen((change) {
      print(" Database change detected: $change");
      sendUpdateToClients(jsonEncode(change)); // Send update to WebSocket clients
    });
  }
  //used to send update to clients
  void sendUpdateToClients(String message) {
    for (var client in clients) {
      client.add(message);
    }
    print("Sent update to ${clients.length} clients");
  }
}



// class WebsocketServer{
//   static final WebsocketServer _singleton = WebsocketServer._internal();
//
//   factory WebsocketServer() => _singleton;
//   final int port;
//   bool _isRunning = false;
//   final List<WebSocket> clients = []; // List to store connected clients
//   WebsocketServer._internal({
//     this.port = PORT,});
//
//
//
//
//   // A function to start the WebSocket server
//   Future<void> start() async{
//     if (_isRunning) {
//       print('WebSocket server is already running.');
//       return;
//     }
//
//     _isRunning = true;
//     print('Starting WebSocket server...');
//     await MongoDB_Server.connect();
//
//     HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
//     print("WebSocket Server running on ws://localhost:$port");
//
//     server.transform(WebSocketTransformer()).listen((WebSocket socket) async {
//       clients.add(socket);
//       print("New WebSocket client connected");
//
//       // Send existing data to the new client
//       await sendExistingData(socket);
//
//       socket.done.then((_) {
//         print("WebSocket client disconnected");
//         clients.remove(socket);
//       });
//     });
//     // await MongoDB_Server.watchChanges();
//        watchDatabaseChanges();
//     }
//    bool isRunning() {
//      return _isRunning;
//     }
//   Future<void> sendExistingData(WebSocket socket) async {
//     var data = await MongoDB_Server.collection.find().toList();
//     socket.add(jsonEncode(data)); // Send existing data as JSON
//   }
//
//   //used to watch changes in database
//   void watchDatabaseChanges() {
//     MongoDB_Server.watchChanges().listen((change) {
//       print(" Database change detected: $change");
//       sendUpdateToClients(jsonEncode(change)); // Send update to WebSocket clients
//     });
//   }
//   //used to send update to clients
//   void sendUpdateToClients(String message) {
//     for (var client in clients) {
//       client.add(message);
//     }
//     print("Sent update to ${clients.length} clients");
//   }
// }




