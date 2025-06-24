import 'package:mongo_dart/mongo_dart.dart';
import 'constant.dart';

class MongoDatabase {
  static late Db db;
  static late DbCollection userCollection;
  static late DbCollection localityCollection;
  static late DbCollection routeCollection;
  static late DbCollection driverCollection;
  static Future<void> connect() async {
    db = await Db.create(MONGO_CONN_URL);
    await db.open();
    userCollection = db.collection(USER_COLLECTION);
    localityCollection = db.collection('localities'); // <- Agregamos esto
    routeCollection = db.collection('route'); // <- Agrega esto
    driverCollection = db.collection('drivers');

    print("✅ Conexión a MongoDB exitosa");
  }

  static Future<Map<String, dynamic>?> findUser(String email, String password) async {
    final user = await userCollection.findOne({
      'email': email,
      'password': password,
    });
    return user;
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
  final collection = db.collection('localities');
  await collection.deleteOne({'id': id});
}


  static Future<List<Map<String, dynamic>>> getAllRoutes() async {
  final result = await routeCollection.find().toList();
  print("Rutas obtenidas en MongoDatabase: ${result.length}");
  return result.cast<Map<String, dynamic>>();
}
static Future<void> addRoute(Map<String, dynamic> data) async {
  final collection = db.collection('route');
  await collection.insertOne(data);
  print('✅ Ruta agregada con éxito');
}
static Future<void> deleteRoute(dynamic id) async {
  try {
    // Si tu id es un int o String, asegúrate de usar el tipo correcto
    await routeCollection.deleteOne({'id': id});
    print('✅ Ruta eliminada con éxito');
  } catch (e) {
    print('❌ Error al eliminar ruta: $e');
    rethrow;
  }
}
static Future<void> updateRoute(dynamic id, Map<String, dynamic> newData) async {
  try {
    // No reemplazamos el id, solo los campos actualizables
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

  
}
