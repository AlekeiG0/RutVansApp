import 'dart:io'; // ← para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ← image_picker

import '../widgets/App_Scaffold.dart'; // ← tu widget AppScaffold
import '../dbHelper/horariost.dart';
class HorariosPage extends StatefulWidget {
  const HorariosPage({super.key});

  @override
  State<HorariosPage> createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  List<Map<String, dynamic>> conductores = [];
  List<Map<String, dynamic>> rutas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final drivers = await MongoDatabase.getAllDrivers();
    final rutasDB = await MongoDatabase.getAllRoutes();
    setState(() {
      conductores = drivers;
      rutas = rutasDB;
    });
  }

  void _asignarRuta(BuildContext ctx, Map<String, dynamic> conductor) {
    Map<String, dynamic>? rutaSeleccionada;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Asignar Ruta",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: const InputDecoration(labelText: "Ruta"),
                items: rutas.map((ruta) {
                  return DropdownMenuItem(
                    value: ruta,
                    child: Text(
                      "${ruta['departure']} → ${ruta['arrival']}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  rutaSeleccionada = value;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Asignar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (rutaSeleccionada == null) return;
                  await MongoDatabase.addDriverRoute({
                    'driver_id': conductor['_id'].toHexString(),
                    'unit_id': rutaSeleccionada!['id'],
                    'departure': rutaSeleccionada!['departure'],
                    'arrival': rutaSeleccionada!['arrival'],
                    'status': true,
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarRutasAsignadas(BuildContext ctx, Map<String, dynamic> conductor) async {
    final driverId = conductor['_id'].toHexString();
    final rutasAsignadas = await MongoDatabase.getDriverRoutes(driverId);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rutas asignadas a ${conductor['name']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (rutasAsignadas.isEmpty)
                const Text("No hay rutas asignadas.", style: TextStyle(fontSize: 16)),
              for (final ruta in rutasAsignadas)
                ListTile(
                  title: Text('${ruta['departure']} → ${ruta['arrival']}'),
                  subtitle: Text('Estado: ${ruta['status'] == true ? "Activo" : "Inactivo"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editarRutaAsignada(context, ruta, conductor);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await MongoDatabase.deleteDriverRoute(ruta['_id']);
                          Navigator.pop(ctx);
                          _mostrarRutasAsignadas(ctx, conductor); // Recargar
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _editarRutaAsignada(BuildContext ctx, Map<String, dynamic> ruta, Map<String, dynamic> conductor) {
    final depCtrl = TextEditingController(text: ruta['departure']);
    final arrCtrl = TextEditingController(text: ruta['arrival']);
    bool status = ruta['status'] == true;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Editar Ruta",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: depCtrl, decoration: const InputDecoration(labelText: "Salida")),
              TextField(controller: arrCtrl, decoration: const InputDecoration(labelText: "Llegada")),
              SwitchListTile(
                value: status,
                onChanged: (val) => setState(() => status = val),
                title: const Text("¿Activa?"),
                activeColor: Colors.orange,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Actualizar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await MongoDatabase.updateDriverRoute(ruta['_id'], {
                    'departure': depCtrl.text,
                    'arrival': arrCtrl.text,
                    'status': status,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  Navigator.pop(ctx);
                  _mostrarRutasAsignadas(ctx, conductor); // Recargar tras actualizar
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      currentDrawerIndex: 8,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: conductores.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, i) {
            final data = conductores[i];
            final foto = data['photo'] ?? 'images/default.jpg';
            final isLocal = foto.toString().startsWith('/');
            final widgetImg = isLocal
                ? Image.file(File(foto), fit: BoxFit.cover)
                : Image.asset(foto, fit: BoxFit.cover);

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                      child: ClipOval(child: SizedBox(width: 80, height: 80, child: widgetImg)),
                    ),
                    const SizedBox(height: 10),
                    Text(data['name'] ?? 'Sin nombre',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.route),
                      label: const Text("Asignar Ruta"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _asignarRuta(context, data),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text("Ver Rutas"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade200,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _mostrarRutasAsignadas(context, data),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}