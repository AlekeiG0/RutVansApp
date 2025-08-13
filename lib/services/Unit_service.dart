import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UnitService {
  // ✅ Usamos ApiConfig para centralizar la URL
  String get _baseUrl => '${ApiConfig.baseUrl}/api/admin';

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print('Token obtenido: $token');
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getUnits() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/units'), headers: headers);
      // 📌 LOG COMPLETO
  print('📡 [GET Units] Status: ${response.statusCode}');
  print('📡 [GET Units] Headers: ${response.headers}');
  print('📡 [GET Units] Body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener unidades');
    }
  }

  Future<Map<String, dynamic>> getUnitById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/units/$id'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener unidad');
    }
  }

  Future<List<dynamic>> getSites() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/sites'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener sitios');
    }
  }

  Future<Map<String, dynamic>> createUnit(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/units'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al crear unidad');
    }
  }

  Future<Map<String, dynamic>> updateUnit(String id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/units/$id'),
      headers: headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al actualizar unidad');
    }
  }

  Future<void> deleteUnit(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$_baseUrl/units/$id'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Error al eliminar unidad');
    }
  }

  Future<Map<String, dynamic>> createUnitWithPhoto({
    required String plate,
    required int capacity,
    required int siteId,
    File? photoFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/units');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['plate'] = plate
      ..fields['capacity'] = capacity.toString()
      ..fields['site_id'] = siteId.toString();

    if (photoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al crear unidad con foto');
    }
  }

  Future<Map<String, dynamic>> updateUnitWithPhoto({
    required String id,
    String? plate,
    int? capacity,
    int? siteId,
    File? photoFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final uri = Uri.parse('$_baseUrl/units/$id');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['_method'] = 'PATCH';

    if (plate != null) request.fields['plate'] = plate;
    if (capacity != null) request.fields['capacity'] = capacity.toString();
    if (siteId != null) request.fields['site_id'] = siteId.toString();

    if (photoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al actualizar unidad con foto');
    }
  }
}
