import 'mongodb.dart';

class DriverService {
  static Future<List<Map<String, dynamic>>> getAllDrivers() async {
    final result = await MongoDatabase.driverCollection.find().toList();
    print("Conductores obtenidos: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }
}
