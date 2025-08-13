import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // ❌ Eliminamos esta línea fija:
  // static const String baseUrl = 'https://apimongo-n2ss.onrender.com/api';

  // ✅ Usamos ApiConfig.baseUrl dinámicamente
  static String get _baseUrl => '${ApiConfig.baseUrl}/api';

  // Método para obtener headers con token
  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 🔹 Resumen del dashboard
  static Future<Map<String, dynamic>> fetchResumen() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/dashboard/resumen'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener resumen: ${response.body}');
    }
  }

  // 🔹 Obtener ventas
  static Future<List<dynamic>> fetchVentas() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/ventas'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener ventas: ${response.body}');
    }
  }

  // 🔹 Obtener rutas
  static Future<List<dynamic>> fetchRutas() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/routes'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener rutas: ${response.body}');
    }
  }

  // 🔹 Obtener conductores con total incluido
  static Future<Map<String, dynamic>> fetchConductores() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/drivers'),
      headers: headers,
    );

    print('fetchConductores: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Conductores decoded: $data');
      return data;
    } else {
      throw Exception('Error al obtener conductores: ${response.body}');
    }
  }
}
