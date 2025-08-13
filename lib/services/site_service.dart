import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SiteService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/admin/sites';

  // 🔐 Obtener encabezados con token guardado
  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    print('🔑 Token actual: $token'); // LOG DEL TOKEN

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 📌 Obtener sitios de la compañía del usuario
  static Future<List<dynamic>> getSites() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(_baseUrl);

      print('🌐 URL solicitada: $url'); // LOG DE LA URL
      print('📩 Headers enviados: $headers'); // LOG DE HEADERS

      final response = await http.get(url, headers: headers);

      print('📦 Código de respuesta: ${response.statusCode}'); // LOG STATUS CODE
      print('📜 Respuesta cruda: ${response.body}'); // LOG BODY RAW

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('✅ Total de sitios recibidos: ${data.length}');
        for (var site in data) {
          print('🏢 Sitio: ${site['name']} | Compañía ID: ${site['company_id']}');
        }

        // Aquí puedes filtrar si quieres verificar que todos son de la misma compañía
        return data;
      } else {
        print('❌ Error al obtener sitios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('⚠️ Error en getSites: $e');
      return [];
    }
  }
}
