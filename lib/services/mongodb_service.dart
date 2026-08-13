import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb

class MongoDbService {
  static final MongoDbService _instance = MongoDbService._internal();
  factory MongoDbService() => _instance;
  MongoDbService._internal();

  Db? _db;
  bool _isConnected = false;

  /// Initialize the database connection
  Future<void> init() async {
    // Check if we're running on web - MongoDB connections don't work on web
    if (kIsWeb) {
      print('Running on web - MongoDB connections not supported');
      _isConnected = false;
      return;
    }
    
    print('Initializing MongoDB connection on non-web platform');

    try {
      // Get MongoDB URI from environment variables
      final uri = dotenv.env['MONGODB_URI'];

      if (uri == null || uri.isEmpty) {
        throw Exception('MongoDB URI not found in environment variables');
      }

      // Create database connection
      print('Creating MongoDB connection with URI: $uri');
      _db = await Db.create(uri);
      await _db!.open();
      _isConnected = true;
      print('Successfully connected to MongoDB Atlas');
    } catch (e) {
      print('Failed to connect to MongoDB Atlas: $e');
      _isConnected = false;
    }
  }

  /// Check if database is connected
  bool get isConnected => _isConnected;

  /// Get database instance
  Db? get database => _db;

  /// Get collection reference
  DbCollection collection(String name) {
    if (_db == null) {
      throw Exception('Database not initialized');
    }
    return _db!.collection(name);
  }

  /// Close database connection
  Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      _isConnected = false;
    }
  }

  /// Insert a document
  Future<String?> insertDocument(
    String collectionName,
    Map<String, dynamic> document,
  ) async {
    try {
      final collection = this.collection(collectionName);
      final result = await collection.insertOne(document);
      return result.id;
    } catch (e) {
      print('Error inserting document: $e');
      return null;
    }
  }

  /// Find documents
  Future<List<Map<String, dynamic>>> findDocuments(
    String collectionName, {
    Map<String, dynamic>? filter,
  }) async {
    try {
      final collection = this.collection(collectionName);
      final result = await collection.find(filter ?? {}).toList();
      return result.map((doc) => doc..remove('_id')).toList();
    } catch (e) {
      print('Error finding documents: $e');
      return [];
    }
  }

  /// Update a document
  Future<bool> updateDocument(
    String collectionName,
    Map<String, dynamic> filter,
    Map<String, dynamic> update,
  ) async {
    try {
      final collection = this.collection(collectionName);
      final result = await collection.updateOne(filter, update);
      return result.isSuccess;
    } catch (e) {
      print('Error updating document: $e');
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(
    String collectionName,
    Map<String, dynamic> filter,
  ) async {
    try {
      final collection = this.collection(collectionName);
      final result = await collection.deleteOne(filter);
      return result.isSuccess;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }
}