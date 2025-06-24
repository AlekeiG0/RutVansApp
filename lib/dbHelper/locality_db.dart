import 'mongodb.dart';

class LocalityService {
  static Future<List<Map<String, dynamic>>> getAllLocalities() async {
    final result = await MongoDatabase.localityCollection.find().toList();
    print("Localities obtenidas: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }

  static Future<void> addLocality(Map<String, dynamic> data) async {
    try {
      await MongoDatabase.localityCollection.insertOne(data);
      print('✅ Localidad insertada con éxito');
    } catch (e) {
      print('❌ Error al insertar localidad: $e');
      rethrow;
    }
  }

  static Future<void> deleteLocality(int id) async {
    await MongoDatabase.localityCollection.deleteOne({'id': id});
  }
}
