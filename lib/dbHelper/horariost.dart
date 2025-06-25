import 'package:mongo_dart/mongo_dart.dart';
import 'constant.dart';

class MongoDatabase {
  static late Db db;
  static late DbCollection userCollection;
  static late DbCollection localityCollection;
  static late DbCollection routeCollection;
  static late DbCollection driverCollection;
  static late DbCollection driverUnitCollection;

  static Future<void> connect() async {
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    userCollection = db.collection(USER_COLLECTION);
    localityCollection = db.collection(LOCALITY_COLLECTION);
    routeCollection = db.collection(ROUTE_COLLECTION);
    driverCollection = db.collection(DRIVER_COLLECTION);
    driverUnitCollection = db.collection(DRIVER_UNIT_COLLECTION);

    print("✅ Conexión a MongoDB exitosa");
  }

  static Future<Map<String, dynamic>?> findUser(String email, String password) async {
    final user = await userCollection.findOne({
      'email': email,
      'password': password,
    });
    return user;
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final user = await userCollection.findOne({'email': email});
      return user;
    } catch (e) {
      print('❌ Error buscando usuario por email: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllLocalities() async {
    final result = await localityCollection.find().toList();
    print("Localities obtenidas en MongoDatabase: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }

  static Future<void> addLocality(Map<String, dynamic> data) async {
    try {
      await localityCollection.insertOne(data);
      print('✅ Localidad insertada con éxito');
    } catch (e) {
      print('❌ Error al insertar localidad: $e');
      rethrow;
    }
  }

  static Future<void> deleteLocality(int id) async {
    await localityCollection.deleteOne({'id': id});
  }

  static Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final result = await routeCollection.find().toList();
    print("Rutas obtenidas en MongoDatabase: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }

  static Future<void> addRoute(Map<String, dynamic> data) async {
    await routeCollection.insertOne(data);
    print('✅ Ruta agregada con éxito');
  }

  static Future<void> deleteRoute(dynamic id) async {
    try {
      await routeCollection.deleteOne({'id': id});
      print('✅ Ruta eliminada con éxito');
    } catch (e) {
      print('❌ Error al eliminar ruta: $e');
      rethrow;
    }
  }

  static Future<void> updateRoute(dynamic id, Map<String, dynamic> newData) async {
    try {
      await routeCollection.updateOne(
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

  static Future<List<Map<String, dynamic>>> getAllDrivers() async {
    final result = await driverCollection.find().toList();
    print("Conductores obtenidos en MongoDatabase: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getDriverRoutes(String driverId) async {
    final result = await driverUnitCollection.find({'driver_id': driverId}).toList();
    return result.cast<Map<String, dynamic>>();
  }

  static Future<void> addDriverRoute(Map<String, dynamic> data) async {
    try {
      await driverUnitCollection.insertOne(data);
      print("✅ Ruta asignada al conductor con éxito");
    } catch (e) {
      print("❌ Error al asignar ruta al conductor: $e");
    }
  }

  static Future<void> deleteDriverRoute(dynamic id) async {
    try {
      await driverUnitCollection.deleteOne({'_id': id});
      print("✅ Ruta eliminada del conductor con éxito");
    } catch (e) {
      print("❌ Error al eliminar ruta del conductor: $e");
    }
  }

  static Future<void> updateDriverRoute(dynamic id, Map<String, dynamic> newData) async {
    try {
      await driverUnitCollection.updateOne(
        where.id(id),
        modify
          ..set('departure', newData['departure'])
          ..set('arrival', newData['arrival'])
          ..set('status', newData['status'])
          ..set('updated_at', DateTime.now().toIso8601String()),
      );
      print("✅ Ruta del conductor actualizada con éxito");
    } catch (e) {
      print("❌ Error al actualizar ruta del conductor: $e");
    }
  }
}