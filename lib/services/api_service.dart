import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
static const String baseUrl = 'http://192.168.0.172:3000/api/finanzas';
  static Future<Map<String, dynamic>> getResumenFinanciero({String? desde, String? hasta}) async {
    final uri = Uri.parse('$baseUrl/resumen').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error ${response.statusCode} al obtener el resumen financiero');
  }

  static Future<List<Map<String, dynamic>>> getDetalleVentasPorFecha(String fecha) async {
    final uri = Uri.parse('$baseUrl/ventas-detalle?fecha=$fecha');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error ${response.statusCode} al obtener ventas por fecha');
  }

  static Future<Map<String, dynamic>> getVentasPeriodo({String? desde, String? hasta}) async {
    final uri = Uri.parse('$baseUrl/ventas-periodo').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    throw Exception('Error ${response.statusCode} al obtener ventas por periodo');
  }

  static Future<List<Map<String, dynamic>>> getTopRutas({String? desde, String? hasta}) async {
    final uri = Uri.parse('$baseUrl/top-rutas').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error ${response.statusCode} al obtener rutas top');
  }

  static Future<List<Map<String, dynamic>>> getBalanceHistorico({
    String? periodo,
    String? desde,
    String? hasta,
  }) async {
    final uri = Uri.parse('$baseUrl/balance-historico').replace(queryParameters: {
      if (periodo != null) 'periodo': periodo,
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error ${response.statusCode} al obtener balance histórico');
  }

  static Future<List<Map<String, dynamic>>> getEgresosPorCategoria({String? desde, String? hasta}) async {
    final uri = Uri.parse('$baseUrl/egresos-categorias').replace(queryParameters: {
      if (desde != null) 'desde': desde,
      if (hasta != null) 'hasta': hasta,
    });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error ${response.statusCode} al obtener egresos por categoría');
  }

  static Future<Map<String, dynamic>> getVentasPorFecha({required String fecha}) async {
    final uri = Uri.parse('$baseUrl/ventas-detalle').replace(queryParameters: {
      'fecha': fecha,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return {
        'ventas': List<Map<String, dynamic>>.from(json.decode(response.body))
      };
    } else {
      print('Error al obtener ventas por fecha: ${response.statusCode}');
      throw Exception('Error al obtener ventas detalladas');
    }
  }



}
