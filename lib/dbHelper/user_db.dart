import 'mongodb.dart';

class UserService {
  static Future<Map<String, dynamic>?> findUser(String email, String password) async {
    final user = await MongoDatabase.userCollection.findOne({
      'email': email,
      'password': password,
    });
    return user;
  }
}
