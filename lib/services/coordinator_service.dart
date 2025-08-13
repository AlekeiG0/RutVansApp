import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';

class CoordinatorService {
  final String _baseUrl = '${ApiConfig.baseUrl}/api/admin/coordinates';

  // Obtener headers con token Authorization
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Listar coordinadores (index)
  Future<List<dynamic>> fetchCoordinators({int? siteId}) async {
    var url = Uri.parse(_baseUrl);
    if (siteId != null) {
      url = Uri.parse('$_baseUrl?site_id=$siteId');
    }
    final headers = await _getHeaders();
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Error al cargar coordinadores');
    }
  }

  // Mostrar coordinador específico (show)
  Future<dynamic> fetchCoordinator(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      throw Exception('Coordinador no encontrado');
    }
  }

  // Crear coordinador (store) con foto opcional (multipart/form-data)
  Future<dynamic> createCoordinator({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String employeeCode,
    int? siteId,
    File? photo,
  }) async {
    final uri = Uri.parse(_baseUrl);
    final headers = await _getHeaders();
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(headers);

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['phone_number'] = phoneNumber;
    request.fields['employee_code'] = employeeCode;
    if (siteId != null) request.fields['site_id'] = siteId.toString();

    if (photo != null) {
      final multipartFile = await http.MultipartFile.fromPath('photo', photo.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al crear coordinador: ${response.statusCode} - ${response.body}');
    }
  }

  // Actualizar coordinador (update) con foto opcional (multipart/form-data)
  Future<dynamic> updateCoordinator(
    int id, {
    String? name,
    String? email,
    String? phoneNumber,
    String? employeeCode,
    int? siteId,
    File? photo,
    String? newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(headers);

    // Laravel: override PATCH con _method
    request.fields['_method'] = 'PATCH';

    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (phoneNumber != null) request.fields['phone_number'] = phoneNumber;
    if (employeeCode != null) request.fields['employee_code'] = employeeCode;
    if (siteId != null) request.fields['site_id'] = siteId.toString();

    if (newPassword != null && newPassword.isNotEmpty) {
      request.fields['new_password'] = newPassword;
    }

    if (photo != null) {
      final multipartFile = await http.MultipartFile.fromPath('photo', photo.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al actualizar coordinador: ${response.statusCode} - ${response.body}');
    }
  }

  // Eliminar coordinador (delete)
  Future<void> deleteCoordinator(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();
    final res = await http.delete(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Error al eliminar coordinador');
    }
  }
}
