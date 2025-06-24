import 'package:flutter/material.dart';
import '../dbHelper/mongodb.dart';
import '../widgets/App_Scaffold.dart';

class RutasPage extends StatefulWidget {
  const RutasPage({super.key});

  @override
  State<RutasPage> createState() => _RutasPageState();
}

class _RutasPageState extends State<RutasPage> {
  List<Map<String, dynamic>> _rutas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRutas();
  }

  // Función para mostrar un diálogo de carga modal
  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _fetchRutas() async {
    try {
      await MongoDatabase.connect();

      final rutasData = await MongoDatabase.getAllRoutes();
      final localitiesData = await MongoDatabase.getAllLocalities();

      final rutasCompletas = rutasData.map((ruta) {
        final inicio = localitiesData.firstWhere(
          (loc) => loc['id'].toString() == ruta['id_location_s'].toString(),
          orElse: () => <String, dynamic>{},
        );
        final fin = localitiesData.firstWhere(
          (loc) => loc['id'].toString() == ruta['id_location_f'].toString(),
          orElse: () => <String, dynamic>{},
        );

        return {
          'id': ruta['id'],
          'inicio': inicio,
          'fin': fin,
        };
      }).where((r) => r['inicio'].isNotEmpty && r['fin'].isNotEmpty).toList();

      setState(() {
        _rutas = rutasCompletas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar rutas.';
        _loading = false;
      });
    }
  }

  Future<void> _eliminarRuta(dynamic rutaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que quieres eliminar esta ruta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        _mostrarCargando();
        await MongoDatabase.deleteRoute(rutaId);
        Navigator.pop(context); // Cierra el diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta eliminada')),
        );
        _fetchRutas();
      } catch (e) {
        Navigator.pop(context); // Cierra el diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la ruta')),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return AppScaffold(
    currentIndex: 0,
    currentDrawerIndex: 4, 
    body: Scaffold(
      appBar: AppBar(title: const Text('Rutas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rutas.length,
                  itemBuilder: (context, index) {
                    final ruta = _rutas[index];
                    final inicio = ruta['inicio'];
                    final fin = ruta['fin'];

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.alt_route, color: Colors.teal, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${inicio['locality']} → ${fin['locality']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () => _mostrarFormularioRuta(context, editar: true, ruta: ruta),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _eliminarRuta(ruta['id']),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('🚐 Desde: ${inicio['street']}, ${inicio['municipality']}'),
                            Text('🚐 Hacia: ${fin['street']}, ${fin['municipality']}'),
                            Text('📍 ${inicio['state']}, ${inicio['country']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioRuta(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Ruta'),
        backgroundColor: Colors.teal,
      ),
    ),
  );
}


  void _mostrarFormularioRuta(BuildContext context, {bool editar = false, Map<String, dynamic>? ruta}) async {
    final localidades = await MongoDatabase.getAllLocalities();

    int? selectedInicioId = editar ? int.tryParse(ruta!['inicio']['id'].toString()) : null;
    int? selectedFinId = editar ? int.tryParse(ruta!['fin']['id'].toString()) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editar ? 'Editar Ruta' : 'Nueva Ruta',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: selectedInicioId,
                decoration: const InputDecoration(labelText: 'Localidad de inicio'),
                items: localidades.map<DropdownMenuItem<int>>((loc) {
                  return DropdownMenuItem<int>(
                    value: loc['id'],
                    child: Text(loc['locality']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedInicioId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedFinId,
                decoration: const InputDecoration(labelText: 'Localidad de destino'),
                items: localidades.map<DropdownMenuItem<int>>((loc) {
                  return DropdownMenuItem<int>(
                    value: loc['id'],
                    child: Text(loc['locality']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedFinId = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(editar ? 'Guardar cambios' : 'Guardar'),
             onPressed: () async {
  if (selectedInicioId != null && selectedFinId != null) {
    // Mostrar diálogo y esperar un instante para que se renderice
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Pequeña espera para que el diálogo se renderice antes de la operación
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (editar && ruta != null) {
        final rutaEditada = {
          'id_location_s': selectedInicioId,
          'id_location_f': selectedFinId,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await MongoDatabase.updateRoute(ruta['id'], rutaEditada);
      } else {
        final nuevaRuta = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'id_location_s': selectedInicioId,
          'id_location_f': selectedFinId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        await MongoDatabase.addRoute(nuevaRuta);
      }

      Navigator.pop(context); // Cerrar diálogo carga
      Navigator.pop(context); // Cerrar formulario bottom sheet
      _fetchRutas();
    } catch (e) {
      Navigator.pop(context); // Cerrar diálogo carga
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la ruta')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selecciona ambas localidades')),
    );
  }
},

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
