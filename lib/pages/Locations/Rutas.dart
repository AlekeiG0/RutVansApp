import 'package:flutter/material.dart';
import '../../services/Route_service.dart';
import '../../services/locality_api_service.dart';
import '../../services/site_service.dart'; // Importa tu servicio de sitios
import '../../widgets/App_Scaffold.dart';

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

  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _fetchRutas() async {
    try {
      final rutasData = await RouteService.getAllRoutes();

      final rutasCompletas = rutasData.map((ruta) {
        return {
          'id': ruta['id'] ?? ruta['_id'],
          'inicio': ruta['location_start'] ?? {},
          'fin': ruta['location_end'] ?? {},
          'site': ruta['site'] ?? {}, // El sitio debe venir en la respuesta API
        };
      }).toList();

      setState(() {
        _rutas = rutasCompletas;
        _loading = false;
        _error = null;
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
        await RouteService.deleteRoute(rutaId);
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
      currentIndex: -1,
      currentDrawerIndex: 6,
      appBarTitle: 'Rutas',
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
                    final inicio = ruta['inicio'] ?? {};
                    final fin = ruta['fin'] ?? {};
                    final site = ruta['site'] ?? {};

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
                                    '${inicio['locality'] ?? 'Inicio'} → ${fin['locality'] ?? 'Fin'}',
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
                            Text('🚐 Desde: ${inicio['street'] ?? '-'}, ${inicio['municipality'] ?? '-'}'),
                            Text('🚐 Hacia: ${fin['street'] ?? '-'}, ${fin['municipality'] ?? '-'}'),
                            Text('📍 ${inicio['state'] ?? '-'}, ${inicio['country'] ?? '-'}'),
                            const SizedBox(height: 8),
                            Text('🏢 Sitio: ${site['name'] ?? '-'}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal)),
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
      ), title: '',
    );
  }

  void _mostrarFormularioRuta(BuildContext context,
      {bool editar = false, Map<String, dynamic>? ruta}) async {
    final localidades = await LocalityApiService.getAllLocalities();
    final sitios = await SiteService.getSites(); // Carga los sitios

    String? selectedInicioId = editar ? ruta!['inicio']['id']?.toString() : null;
    String? selectedFinId = editar ? ruta!['fin']['id']?.toString() : null;
    String? selectedSiteId;
    if (editar && ruta != null && ruta['site'] != null) {
      selectedSiteId = ruta['site']['id']?.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
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
                DropdownButtonFormField<String>(
                  value: selectedInicioId,
                  decoration: const InputDecoration(labelText: 'Localidad de inicio'),
                  items: localidades.map<DropdownMenuItem<String>>((loc) {
                    return DropdownMenuItem<String>(
                      value: loc['id'].toString(),
                      child: Text(loc['locality']),
                    );
                  }).toList(),
                  onChanged: (value) => setModalState(() => selectedInicioId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedFinId,
                  decoration: const InputDecoration(labelText: 'Localidad de destino'),
                  items: localidades.map<DropdownMenuItem<String>>((loc) {
                    return DropdownMenuItem<String>(
                      value: loc['id'].toString(),
                      child: Text(loc['locality']),
                    );
                  }).toList(),
                  onChanged: (value) => setModalState(() => selectedFinId = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSiteId,
                  decoration: const InputDecoration(labelText: 'Sitio'),
                  items: sitios.map<DropdownMenuItem<String>>((site) {
                    return DropdownMenuItem<String>(
                      value: site['id'].toString(),
                      child: Text(site['name']),
                    );
                  }).toList(),
                  onChanged: (value) => setModalState(() => selectedSiteId = value),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(editar ? 'Guardar cambios' : 'Guardar'),
                    onPressed: () async {
                      if (selectedInicioId != null && selectedFinId != null && selectedSiteId != null) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        await Future.delayed(const Duration(milliseconds: 100));
                        try {
                          final payload = {
                            'location_s_id': selectedInicioId,
                            'location_f_id': selectedFinId,
                            'site_id': selectedSiteId,
                          };

                          if (editar && ruta != null) {
                            await RouteService.updateRoute(ruta['id'], payload);
                          } else {
                            await RouteService.addRoute(payload);
                          }

                          Navigator.pop(context); // cerrar loading
                          Navigator.pop(context); // cerrar modal
                          _fetchRutas();
                        } catch (e) {
                          Navigator.pop(context); // cerrar loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al guardar la ruta')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selecciona todas las opciones')),
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
        });
      },
    );
  }
}
