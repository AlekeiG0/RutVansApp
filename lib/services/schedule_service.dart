import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ScheduleService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/admin/route-unit-schedules';
  static String get _routeUnitsUrl => '${ApiConfig.baseUrl}/api/admin/units';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getSchedules() async {
    final url = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    print('📥 GET $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar horarios: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<dynamic>> getRouteUnits() async {
    final url = Uri.parse(_routeUnitsUrl);
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);

    print('📥 GET $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar las unidades de ruta: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> createSchedule({
    required int routeUnitId,
    required String scheduleDate,
    required String scheduleTime,
    required String status,
  }) async {
    final url = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({
        'route_unit_id': routeUnitId,
        'schedule_date': scheduleDate,
        'schedule_time': scheduleTime,
        'status': status,
      }),
    );

    print('📥 POST $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception('Error al crear horario: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateSchedule({
    required int id,
    required int routeUnitId,
    required String scheduleDate,
    required String scheduleTime,
    required String status,
  }) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode({
        'route_unit_id': routeUnitId,
        'schedule_date': scheduleDate,
        'schedule_time': scheduleTime,
        'status': status,
      }),
    );

    print('📥 PUT $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar horario: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> deleteSchedule(int id) async {
    final url = Uri.parse('$_baseUrl/$id');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    print('📥 DELETE $url');
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar horario: ${response.statusCode} - ${response.body}');
    }
  }
}