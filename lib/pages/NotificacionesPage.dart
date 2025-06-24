import 'package:flutter/material.dart';
import '../widgets/App_Scaffold.dart';

class NotificacionesPage extends StatelessWidget {
  const NotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notificaciones = [
      {
        'titulo': 'Conductor asignado',
        'mensaje': 'Juan Perez ha sido asignado a la ruta 3.',
        'fecha': '27/05/2025',
        'tipo': 'info',
      },
      {
        'titulo': 'Pago confirmado',
        'mensaje': 'Se ha confirmado el pago de Ernesto Martín.',
        'fecha': '26/05/2025',
        'tipo': 'pago',
      },
      {
        'titulo': 'Incidencia reportada',
        'mensaje': 'Se reportó una incidencia en la unidad 12.',
        'fecha': '25/05/2025',
        'tipo': 'alerta',
      },
      {
        'titulo': 'Ruta actualizada',
        'mensaje': 'La ruta Maxcanú ha sido actualizada.',
        'fecha': '24/05/2025',
        'tipo': 'info',
      },
    ];

    Icon _iconoPorTipo(String tipo) {
      switch (tipo) {
        case 'pago':
          return const Icon(Icons.attach_money, color: Colors.green, size: 30);
        case 'alerta':
          return const Icon(Icons.warning, color: Colors.redAccent, size: 30);
        case 'info':
        default:
          return const Icon(Icons.info, color: Colors.blue, size: 30);
      }
    }

   return AppScaffold(
      
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notificaciones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final noti = notificaciones[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: _iconoPorTipo(noti['tipo']!),
              title: Text(
                noti['titulo']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    noti['mensaje']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    noti['fecha']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
