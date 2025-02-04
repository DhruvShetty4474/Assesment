import 'dart:developer';
import 'package:mongo_dart/mongo_dart.dart'; // Ensure this import is included
import 'package:shelf/shelf.dart';
import '../Constant/constant.dart';

// Connect to MongoDB Server
class MongoDB_Server {
  static late Db db;
  static late DbCollection collection;

//Creates an instance of DataBase connection and DbCollection.
  static Future<void> connect() async {
    var db = await Db.create(MONGO_URL);
    await db.open();
    collection = db.collection(COLLECTION_NAME);
    print(await collection.find().toList());
  }

  // Watches for changes in the collection
  static Stream<Map<String, dynamic>> watchChanges() {
    // Define the pipeline to filter for insert, update, and delete operations
    var pipeline = [
      {
        '\$match': {
          'operationType': {'\$in': ['insert', 'update', 'delete']},
        }
      }
    ];

    // Pass the pipeline to the watch() method
    return collection.watch(pipeline).map((change) {
      // When Data is been insterted
      if (change.operationType == 'insert') {
        print("Data Inserted");
        return {'operation': 'insert', 'data': change.fullDocument as Map<String, dynamic>};

      }
      // When Data is been updated
      else if(change.operationType == 'update'){
        print("Data Updated");
        print('Document ID: ${change.fullDocument?['name']}');
        //check if full document is available
        if (change.fullDocument != null) {
          print('Full document after update: ${change.fullDocument as Map<String, dynamic>}');
          return {'operation': 'update', 'data': change.fullDocument as Map<String, dynamic>};
        }
        else {
          // Fetch the full document manually if not available
          return {'operation': 'update', 'document_id': change.documentKey?['_id']};
        }
      }
      // When Data is been deleted returns the id
      else if (change.operationType == 'delete') {
        print('Document deleted:');
        print('Document ID: ${change.documentKey?['_id']}');
        // print('Deleted user: ${change.fullDocument?['name']}');
        return {'operation': 'delete', 'document_id': change.documentKey?['_id']};
      }
      return {};
    });
  }
}
