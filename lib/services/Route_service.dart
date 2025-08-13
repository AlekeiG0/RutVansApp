import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class RouteService {
  // Ya no se necesita esta línea:
  // static const String baseUrl = 'https://apimongo-n2ss.onrender.com/api';

  // Obtener headers con token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    print('🔹 Token recuperado: $token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener todas las rutas
  static Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final headers = await _getHeaders();
    final url = '${ApiConfig.baseUrl}/api/admin/routes';
    print('📡 Solicitando rutas en: $url');

    final response = await http.get(Uri.parse(url), headers: headers);

    print('📥 Status Code: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('✅ Rutas cargadas correctamente (${data.length})');
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      print('❌ Error al cargar rutas: ${response.statusCode}');
      throw Exception('Error al cargar rutas');
    }
  }

  // Agregar nueva ruta
  static Future<void> addRoute(Map<String, dynamic> route) async {
    final headers = await _getHeaders();
    print('📤 Agregando ruta: $route');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/routes'),
      headers: headers,
      body: jsonEncode(route),
    );

    print('📥 Status Code Add: ${response.statusCode}');
    print('📥 Response Add: ${response.body}');

    if (response.statusCode == 201) {
      print('✅ Ruta agregada correctamente');
    } else {
      print('❌ Error al agregar ruta');
      throw Exception('Error al agregar ruta');
    }
  }

  // Actualizar ruta
static Future<void> updateRoute(dynamic id, Map<String, dynamic> route) async {
  final headers = await _getHeaders();
  print('✏️ Actualizando ruta con ID: $id');
  print('📝 Datos enviados: $route');

  final response = await http.patch(
    Uri.parse('${ApiConfig.baseUrl}/api/admin/routes/$id'),
    headers: headers,
    body: jsonEncode(route),
  );

  print('📥 Status Code Update: ${response.statusCode}');
  print('📥 Response Update: ${response.body}');

  if (response.statusCode == 200) {
    print('✅ Ruta actualizada correctamente');
  } else {
    print('❌ Error al actualizar ruta');
    throw Exception('Error al actualizar ruta');
  }
}


  // Eliminar ruta
  static Future<void> deleteRoute(dynamic id) async {
    final headers = await _getHeaders();
    print('🗑️ Eliminando ruta con ID: $id');

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/routes/$id'),
      headers: headers,
    );

    print('📥 Status Code Delete: ${response.statusCode}');
    print('📥 Response Delete: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ Ruta eliminada correctamente');
    } else {
      print('❌ Error al eliminar ruta');
      throw Exception('Error al eliminar ruta');
    }
  }
}
