import 'dart:convert';

class NotificationModel {
  final String id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final DateTime fecha;
  bool leido;

  NotificationModel({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    this.leido = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      tipo: json['tipo'] ?? 'info',
      fecha: DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now(),
      leido: json['leido'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'leido': leido,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
