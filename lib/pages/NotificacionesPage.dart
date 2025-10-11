import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final NotificationService _service = NotificationService();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
  }

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

  void _simularNotificacion() async {
    final n = NotificationModel(
      id: _uuid.v4(),
      titulo: 'Recordatorio de viaje',
      mensaje: 'Tu turno empieza en 30 minutos.',
      tipo: 'info',
      fecha: DateTime.now(),
    );
    await _service.add(n);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      currentDrawerIndex: 0,
      appBarTitle: 'Notificaciones',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simularNotificacion,
        icon: const Icon(Icons.add_alert),
        label: const Text('Simular'),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _service.stream,
        initialData: _service.snapshot,
        builder: (context, snapshot) {
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No hay notificaciones', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _service.clear(),
                    child: const Text('Limpiar'),
                  )
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _service.markAllRead(),
                      child: const Text('Marcar todas como leídas'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _service.clear(),
                      child: const Text('Borrar todo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final noti = list[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: _iconoPorTipo(noti.tipo),
                          title: Text(
                            noti.titulo,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: noti.leido ? Colors.grey : Colors.black),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(noti.mensaje, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                '${noti.fecha.day}/${noti.fecha.month}/${noti.fecha.year} ${noti.fecha.hour.toString().padLeft(2, '0')}:${noti.fecha.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          trailing: noti.leido
                              ? const Icon(Icons.done_all, color: Colors.green)
                              : TextButton(
                                  onPressed: () => _service.markRead(noti.id),
                                  child: const Text('Marcar leída'),
                                ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
