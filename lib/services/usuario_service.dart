import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import '../config/api_config.dart'; // Asegúrate de que contiene ApiConfig.baseUrl

class UsuarioService {
  // Ya no es necesario definir baseUrl aquí

  // Método para obtener el perfil desde la API
  static Future<Map<String, dynamic>?> obtenerPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('⚠️ No hay token guardado');
      return null;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/perfil');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Guardamos datos localmente
      await prefs.setString('nombre_usuario', data['name'] ?? '');
      await prefs.setString('email_usuario', data['email'] ?? '');
      await prefs.setString('foto_usuario', data['profile_photo_url'] ?? '');
      await prefs.setString('direccion_usuario', data['address'] ?? '');
      await prefs.setString('telefono_usuario', data['phone_number'] ?? '');
      await prefs.setString('creado_usuario', data['created_at'] ?? '');
      await prefs.setString('actualizado_usuario', data['updated_at'] ?? '');

      return data;
    } else {
      print('❌ Error al obtener perfil: ${response.statusCode}');
      print(response.body);
      return null;
    }
  }

  // Método para actualizar el perfil con opción de foto
  static Future<bool> actualizarPerfil({
    required String name,
    required String email,
    String? address,
    String? phoneNumber,
    File? profilePhoto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      print('⚠️ No hay token guardado');
      return false;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/actualizarPerfil');

    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['name'] = name;
    request.fields['email'] = email;
    if (address != null) request.fields['address'] = address;
    if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;

    if (profilePhoto != null) {
      var stream = http.ByteStream(profilePhoto.openRead());
      var length = await profilePhoto.length();
      var multipartFile = http.MultipartFile(
        'profile_photo',
        stream,
        length,
        filename: basename(profilePhoto.path),
      );
      request.files.add(multipartFile);
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      var jsonResponse = json.decode(respStr);

      if (jsonResponse['user'] != null) {
        var user = jsonResponse['user'];
        await prefs.setString('nombre_usuario', user['name'] ?? '');
        await prefs.setString('email_usuario', user['email'] ?? '');
        // Puedes añadir más campos si deseas
      }

      return true;
    } else {
      print('❌ Error al actualizar perfil: ${response.statusCode}');
      var respStr = await response.stream.bytesToString();
      print(respStr);
      return false;
    }
  }
}
