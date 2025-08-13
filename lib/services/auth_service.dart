import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static Future<bool> validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null || token.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/validate-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['valid'] == true) {
        return true;
      } else {
        await _clearUserData();
        return false;
      }
    } catch (e) {
      await _clearUserData();
      return false;
    }
  }

  static Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Limpiar datos independientemente de la respuesta del servidor
      await _clearUserData();

      return response.statusCode == 200;
    } catch (e) {
      // Asegurarse de limpiar los datos incluso si hay error en la petición
      await _clearUserData();
      return false;
    }
  }

  static Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nombre_usuario');
    await prefs.remove('email_usuario');
    await prefs.remove('foto_usuario');
    await prefs.remove('password_usuario');
    await prefs.remove('direccion_usuario');
    await prefs.remove('telefono_usuario');
    await prefs.remove('foto_path_usuario');
    await prefs.remove('creado_usuario');
    await prefs.remove('actualizado_usuario');
  }

  // Opcional: Método para obtener el token almacenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}