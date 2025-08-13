import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart'; // Importa tu archivo de configuración

class LaravelApiService {
  // ✅ Base URL dinámico según entorno
  static String get baseUrl => '${ApiConfig.baseUrl}/api/admin/finanzas';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getResumen({String? desde, String? hasta}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/resumen').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Error ${response.statusCode} al obtener resumen financiero');
  }

  static Future<List<Map<String, dynamic>>> getVentasDetalle({String? fecha}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/ventas-detalle').replace(queryParameters: {
      if (fecha != null) 'fecha': fecha,
    });
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
    throw Exception('Error ${response.statusCode} al obtener ventas detalle');
  }

  static Future<List<Map<String, dynamic>>> getVentasPeriodo({String? desde, String? hasta}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/ventas-periodo').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error ${response.statusCode} al obtener ventas por período');
  }

  static Future<List<Map<String, dynamic>>> getTopRutas({String? desde, String? hasta}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/top-rutas').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
    throw Exception('Error ${response.statusCode} al obtener top rutas');
  }

  static Future<List<Map<String, dynamic>>> getBalanceHistorico({String? desde, String? hasta}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/balance-historico').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(json.decode(response.body));
    throw Exception('Error ${response.statusCode} al obtener balance histórico');
  }
}
