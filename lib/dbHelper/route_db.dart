import 'mongodb.dart';
import 'package:mongo_dart/mongo_dart.dart';

class RouteService {
  static Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final result = await MongoDatabase.routeCollection.find().toList();
    print("Rutas obtenidas: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }

  static Future<void> addRoute(Map<String, dynamic> data) async {
    await MongoDatabase.routeCollection.insertOne(data);
    print('✅ Ruta agregada con éxito');
  }

  static Future<void> deleteRoute(dynamic id) async {
    try {
      await MongoDatabase.routeCollection.deleteOne({'id': id});
      print('✅ Ruta eliminada con éxito');
    } catch (e) {
      print('❌ Error al eliminar ruta: $e');
      rethrow;
    }
  }

  static Future<void> updateRoute(dynamic id, Map<String, dynamic> newData) async {
    try {
      await MongoDatabase.routeCollection.updateOne(
        where.eq('id', id),
        modify
          ..set('id_location_s', newData['id_location_s'])
          ..set('id_location_f', newData['id_location_f'])
          ..set('updated_at', DateTime.now().toIso8601String()),
      );
      print('✅ Ruta actualizada con éxito');
    } catch (e) {
      print('❌ Error al actualizar ruta: $e');
      rethrow;
    }
  }
}
