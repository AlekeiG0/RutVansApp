import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';

class CashierService {
  String get _baseUrl => '${ApiConfig.baseUrl}/api/admin/cashiers';

  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Listar cajeros (index)
  Future<List<Map<String, dynamic>>> getCashiers() async {
    final url = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    print('📥 GET $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data'] ?? [];
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Error al obtener cajeros: ${response.statusCode} - ${response.body}');
    }
  }

  // Mostrar cajero específico (show)
  Future<Map<String, dynamic>> getCashier(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    print('📥 GET $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Cajero no encontrado: ${response.statusCode} - ${response.body}');
    }
  }

  // Crear nuevo cajero (store) con foto (multipart/form-data)
  Future<void> createCashier({
    required String nombre,
    required String employeeCode,
    String? telefono,
    required String email,
    required String password,
    required int siteId,
    File? fotoCajero,
  }) async {
    final uri = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['nombre'] = nombre;
    request.fields['employee_code'] = employeeCode;
    if (telefono != null) request.fields['telefono'] = telefono;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['site_id'] = siteId.toString();

    if (fotoCajero != null) {
      final multipartFile = await http.MultipartFile.fromPath('foto_cajero', fotoCajero.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 POST $uri');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear cajero: ${response.statusCode} - ${response.body}');
    }
  }

  // Actualizar cajero (update) con foto opcional (multipart/form-data)
  Future<void> updateCashier(
    int id, {
    String? nombre,
    String? employeeCode,
    String? telefono,
    String? email,
    int? siteId,
    File? fotoCajero,
    String? newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    // Laravel: override PATCH con _method
    request.fields['_method'] = 'PATCH';

    if (nombre != null) request.fields['nombre'] = nombre;
    if (employeeCode != null) request.fields['employee_code'] = employeeCode;
    if (telefono != null) request.fields['telefono'] = telefono;
    if (email != null) request.fields['email'] = email;
    if (siteId != null) request.fields['site_id'] = siteId.toString();
    if (newPassword != null && newPassword.isNotEmpty) {
      request.fields['new_password'] = newPassword;
    }

    if (fotoCajero != null) {
      final multipartFile = await http.MultipartFile.fromPath('foto_cajero', fotoCajero.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 PATCH $uri (como POST con _method=PATCH)');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar cajero: ${response.statusCode} - ${response.body}');
    }
  }

  // Eliminar cajero (delete)
  Future<void> deleteCashier(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    print('📥 DELETE $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar cajero: ${response.statusCode} - ${response.body}');
    }
  }
}
