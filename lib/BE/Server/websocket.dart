import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:filamentai/BE/Server/server.dart'; // Ensure this import is correct
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../Constant/constant.dart'; // Ensure this import is correct

class WebSocketServer {
  final int port;
  final String host;
  late final HttpServer _server;

  WebSocketServer({this.port = 8080, this.host = 'localhost'});

  // Starts the WebSocket server


  // Stops the WebSocket server
  Future<void> stop() async {
    await _server.close();
    print('WebSocket server stopped');
  }
}

class Test {
  Future <void> test_websocket() async{
    await MongoDB_Server.connect();

    //Create a server
    const port = 8080;
    final app = Router();


    //Create routes
    app.get('/', (Request req){
      return Response.ok('Hello World');
    });

    //Listen for the incomming connections..
    final handler = Pipeline().addMiddleware(logRequests()).addHandler(app);

    //Start the server
    final server = await io.serve(handler, InternetAddress.anyIPv4, port);
    print('Server listening on http://${server.address.host}:${server.port}');
  }
}


class WebsocketServer{
  final int port;
  final List<WebSocket> clients = [];
  WebsocketServer({this.port = 8080});

  Future<void> start() async{
    await MongoDB_Server.connect();

    HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print("🚀 WebSocket Server running on ws://localhost:$port");

    server.transform(WebSocketTransformer()).listen((WebSocket socket) async {
      clients.add(socket);
      print("📡 New WebSocket client connected");

      // Send existing data to the new client
      await sendExistingData(socket);

      socket.done.then((_) {
        print("📡 WebSocket client disconnected");
        clients.remove(socket);
      });
    });
    await MongoDB_Server.watchChanges();
    }
  Future<void> sendExistingData(WebSocket socket) async {
    var data = await MongoDB_Server.collection.find().toList();
    socket.add(jsonEncode(data)); // Send existing data as JSON
  }

  void watchDatabaseChanges() {
    MongoDB_Server.watchChanges().listen((change) {
      print(" Database change detected: $change");
      sendUpdateToClients(jsonEncode(change)); // Send update to WebSocket clients
    });
  }
  void sendUpdateToClients(String message) {
    for (var client in clients) {
      client.add(message);
    }
    print("📤 Sent update to ${clients.length} clients");
  }
}




