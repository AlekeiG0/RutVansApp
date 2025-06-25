// ventas.dart
import 'mongodb.dart';

class VentasService {
  static Future<List<Map<String, dynamic>>> getAllventas() async {
    final result = await MongoDatabase.ventasCollection.find().toList();
    print("Ventas obtenidas: ${result.length}");
    return result.cast<Map<String, dynamic>>();
  }
}
