import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LocalityApiService {
  // ✅ Ya no necesitas esta línea:
  // static const String baseUrl = 'https://apimongo-n2ss.onrender.com/api';

  static Future<Map<String, String>> _getHeaders({bool isJson = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      if (isJson) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> getAllLocalities() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/localities');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al obtener localidades: ${response.body}');
    }
  }

  static Future<void> addLocality(Map<String, dynamic> locality) async {
    final headers = await _getHeaders(isJson: true);
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/localities');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(locality),
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al agregar localidad: ${response.body}');
    }
  }

  static Future<void> updateLocality(int id, Map<String, dynamic> updatedData) async {
    final headers = await _getHeaders(isJson: true);
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/localities/$id');

    final response = await http.patch(
      url,
      headers: headers,
      body: json.encode(updatedData),
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar localidad: ${response.body}');
    }
  }

  static Future<void> deleteLocality(int id) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/api/admin/localities/$id');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar localidad: ${response.body}');
    }
  }
}
