import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';
import 'notification_service.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class DriverService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/admin/drivers';

  static Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Obtener lista de conductores
  static Future<List<Map<String, dynamic>>> getDrivers() async {
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
      throw Exception('Error al obtener conductores: ${response.statusCode} - ${response.body}');
    }
  }

  // Obtener un conductor por ID
static Future<Map<String, dynamic>> getDriver(int id) async {
  final url = Uri.parse('$_baseUrl/$id');
  final headers = await _getHeaders();

  final response = await http.get(url, headers: headers);

  print('📥 GET $url');
  print('📥 Response status: ${response.statusCode}');
  print('📥 Response body: ${response.body}');

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    // Aquí la clave 'data' NO existe, retorna jsonData completo
    return jsonData;
  } else {
    throw Exception('Error al obtener conductor: ${response.statusCode} - ${response.body}');
  }
}

  // Crear nuevo conductor con foto (multipart/form-data)
  static Future<void> createDriver({
    required String nombre,
    required String licencia,
    String? telefono,
    required String email,
    required String password,
    File? fotoConductor,
    required int siteId,
  }) async {
    final uri = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['nombre'] = nombre;
    request.fields['licencia'] = licencia;
    if (telefono != null) request.fields['telefono'] = telefono;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['site_id'] = siteId.toString();

    if (fotoConductor != null) {
      final multipartFile = await http.MultipartFile.fromPath('foto_conductor', fotoConductor.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 POST $uri');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al crear conductor: ${response.statusCode} - ${response.body}');
    }
    // Si la creación fue exitosa, intentamos crear una notificación interna
    try {
      final parsed = json.decode(response.body);
      String nombreCreado = '';
      if (parsed is Map<String, dynamic>) {
        if (parsed.containsKey('data')) {
          final data = parsed['data'];
          if (data is Map<String, dynamic>) {
            nombreCreado = data['nombre']?.toString() ?? data['name']?.toString() ?? '';
          }
        } else {
          nombreCreado = parsed['nombre']?.toString() ?? parsed['name']?.toString() ?? '';
        }
      }

      final uuid = const Uuid();
      final notif = NotificationModel(
        id: uuid.v4(),
        titulo: 'Nuevo conductor',
        mensaje: nombreCreado.isNotEmpty ? 'Se creó el conductor $nombreCreado' : 'Se creó un nuevo conductor',
        tipo: 'info',
        fecha: DateTime.now(),
        leido: false,
      );

      await NotificationService().add(notif);
    } catch (e) {
      // No bloquear la creación si falla la notificación; sólo logueamos
      print('[NOTIF] Error al crear notificación interna: $e');
    }
  }

  // Actualizar conductor con foto (multipart/form-data)
   Future<void> updateDriver(
    int id, {
    String? nombre,
    String? licencia,
    String? telefono,
    String? email,
    File? fotoConductor,
    int? siteId,
    String? newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(headers);

    request.fields['_method'] = 'PATCH';

    if (nombre != null) request.fields['nombre'] = nombre;
    if (licencia != null) request.fields['licencia'] = licencia;
    if (telefono != null) request.fields['telefono'] = telefono;
    if (email != null) request.fields['email'] = email;
    if (siteId != null) request.fields['site_id'] = siteId.toString();

    if (newPassword != null && newPassword.isNotEmpty) {
      request.fields['password'] = newPassword;
    }

    if (fotoConductor != null) {
      final multipartFile = await http.MultipartFile.fromPath('foto_conductor', fotoConductor.path);
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('📥 PATCH $uri (como POST con _method=PATCH)');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar conductor: ${response.statusCode} - ${response.body}');
    }
  }

  // Eliminar conductor
   Future<void> deleteDriver(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    print('📥 DELETE $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar conductor: ${response.statusCode} - ${response.body}');
    }
  }
}
