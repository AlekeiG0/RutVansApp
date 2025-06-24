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
    localityCollection = db.collection('localities');
    routeCollection = db.collection('route');
    driverCollection = db.collection('drivers');
    print("✅ Conexión a MongoDB exitosa");
  }
}
