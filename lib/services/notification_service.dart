import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const _storageKey = 'app_notifications_v1';

  final StreamController<List<NotificationModel>> _controller =
      StreamController.broadcast();

  List<NotificationModel> _items = [];

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  Stream<List<NotificationModel>> get stream => _controller.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw) as List<dynamic>;
        _items = parsed
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        _items = [];
      }
    }
    print('[NOTIF] init: loaded ${_items.length} notifications from storage');
    _emit();
  }

  void _emit() => _controller.add(List.unmodifiable(_items));

  Future<void> add(NotificationModel n) async {
    _items.insert(0, n);
    await _save();
    print('[NOTIF] add: ${n.id} - ${n.titulo}');
    _emit();
  }

  Future<void> markRead(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].leido = true;
      await _save();
      print('[NOTIF] markRead: $id');
      _emit();
    }
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i].leido = true;
    }
    await _save();
    print('[NOTIF] markAllRead: total=${_items.length}');
    _emit();
  }

  Future<void> clear() async {
    _items.clear();
    await _save();
    print('[NOTIF] clear: all notifications removed');
    _emit();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
    print('[NOTIF] _save: persisted ${_items.length} notifications');
  }

  List<NotificationModel> get snapshot => List.unmodifiable(_items);

  void dispose() {
    _controller.close();
  }
}
