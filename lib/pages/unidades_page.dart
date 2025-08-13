import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Services/unit_service.dart';
import '../Services/site_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/camera.dart'; // Asegúrate de importar tu CameraPage

class UnitsPage extends StatefulWidget {
  const UnitsPage({Key? key}) : super(key: key);

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  final UnitService _unitService = UnitService();
  List<dynamic> _units = [];
  List<dynamic> _sites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUnitsAndSites();
  }

  Future<void> _loadUnitsAndSites() async {
    setState(() => _loading = true);
    try {
      final units = await _unitService.getUnits();
      final sites = await SiteService.getSites();
      setState(() {
        _units = units;
        _sites = sites;
        _loading = false;
      });
    } catch (e) {
      print('Error al cargar unidades o sitios: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUnit(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que quieres eliminar esta unidad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _unitService.deleteUnit(id);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Unidad eliminada')));
        _loadUnitsAndSites();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error al eliminar unidad')));
      }
    }
  }

  Future<void> _showUnitForm({Map<String, dynamic>? unit}) async {
    final formKey = GlobalKey<FormState>();

    String? plate = unit?['plate'];
    int? capacity = unit?['capacity'];
    String? selectedSiteId = unit?['site']?['id'].toString();
    File? selectedPhoto;

    final rootContext = context;

    await showModalBottomSheet(
      isScrollControlled: true,
      context: rootContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> _pickPhoto() async {
                await showModalBottomSheet(
                  context: context,
                  builder: (BuildContext innerContext) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Galería'),
                          onTap: () async {
                            Navigator.pop(innerContext); // Cierra solo el modal hijo
                            final picker = ImagePicker();
                            final pickedFile =
                                await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setModalState(() =>
                                  selectedPhoto = File(pickedFile.path));
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Cámara'),
                          onTap: () async {
                            Navigator.pop(innerContext); // Cierra solo el modal hijo
                            final imagePath = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CameraPage()),
                            );
                            if (imagePath != null) {
                              setModalState(() => selectedPhoto = File(imagePath));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        unit == null ? 'Agregar Unidad' : 'Editar Unidad',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            if (selectedPhoto != null ||
                                (unit != null && unit['photo'] != null)) {
                              final option = await showModalBottomSheet<String>(
                                context: context,
                                builder: (BuildContext optionContext) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
                                        title: const Text('Seleccionar otra foto'),
                                        onTap: () =>
                                            Navigator.pop(optionContext, 'edit'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete),
                                        title: const Text('Eliminar foto'),
                                        onTap: () =>
                                            Navigator.pop(optionContext, 'delete'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.close),
                                        title: const Text('Cancelar'),
                                        onTap: () =>
                                            Navigator.pop(optionContext, 'cancel'),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (option == 'edit') {
                                // No cierres el modal padre
                                await showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext pickContext) => SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.photo_library),
                                          title: const Text('Galería'),
                                          onTap: () async {
                                            Navigator.pop(pickContext);
                                            final picker = ImagePicker();
                                            final pickedFile = await picker.pickImage(
                                                source: ImageSource.gallery);
                                            if (pickedFile != null) {
                                              setModalState(() =>
                                                  selectedPhoto = File(pickedFile.path));
                                            }
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt),
                                          title: const Text('Cámara'),
                                          onTap: () async {
                                            Navigator.pop(pickContext);
                                            final imagePath = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => const CameraPage()),
                                            );
                                            if (imagePath != null) {
                                              setModalState(
                                                  () => selectedPhoto = File(imagePath));
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (option == 'delete') {
                                setModalState(() {
                                  selectedPhoto = null;
                                  if (unit != null) {
                                    unit['photo'] = null;
                                  }
                                });
                              }
                            } else {
                              await _pickPhoto();
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 140,
                              height: 140,
                              child: selectedPhoto != null
                                  ? Image.file(selectedPhoto!, fit: BoxFit.cover)
                                  : (unit != null && unit['photo'] != null)
                                      ? Image.network(unit['photo'], fit: BoxFit.cover)
                                      : Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image, size: 60),
                                        ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        initialValue: plate,
                        decoration: const InputDecoration(
                          labelText: 'Placa',
                          prefixIcon: Icon(Icons.confirmation_num),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Campo requerido' : null,
                        onSaved: (value) => plate = value,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: capacity?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Capacidad',
                          prefixIcon: Icon(Icons.event_seat),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo requerido';
                          if (int.tryParse(value) == null) return 'Debe ser un número';
                          return null;
                        },
                        onSaved: (value) => capacity = int.tryParse(value ?? ''),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedSiteId,
                        decoration: const InputDecoration(
                          labelText: 'Sitio',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                        items: _sites.map<DropdownMenuItem<String>>((site) {
                          return DropdownMenuItem<String>(
                            value: site['id'].toString(),
                            child: Text(site['name']),
                          );
                        }).toList(),
                        onChanged: (value) => setModalState(() => selectedSiteId = value),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Selecciona un sitio' : null,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt, size: 28),
                          label: Text(
                            unit == null ? 'Guardar' : 'Guardar cambios',
                            style: const TextStyle(fontSize: 18),
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            formKey.currentState!.save();

                            Navigator.of(context).pop(); // cerrar modal

                            showDialog(
                              context: rootContext,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              if (unit == null) {
                                await _unitService.createUnitWithPhoto(
                                  plate: plate!,
                                  capacity: capacity!,
                                  siteId: int.parse(selectedSiteId!),
                                  photoFile: selectedPhoto,
                                );
                              } else {
                                await _unitService.updateUnitWithPhoto(
                                  id: unit['id'].toString(),
                                  plate: plate,
                                  capacity: capacity,
                                  siteId: int.parse(selectedSiteId!),
                                  photoFile: selectedPhoto,
                                );
                              }
                              Navigator.of(rootContext).pop(); // cerrar loading
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(unit == null
                                      ? 'Unidad creada'
                                      : 'Unidad actualizada'),
                                ),
                              );
                              _loadUnitsAndSites();
                            } catch (e) {
                              Navigator.of(rootContext).pop(); // cerrar loading
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                const SnackBar(content: Text('Error al guardar la unidad')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: Colors.teal.shade300,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
@override
Widget build(BuildContext context) {
  return AppScaffold(
    currentIndex: -1,
    currentDrawerIndex: 8,
    appBarTitle: 'Unidades',
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _units.isEmpty
            ? const Center(child: Text('No hay unidades disponibles.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: _units.length,
                itemBuilder: (context, index) {
                  final unit = _units[index];
                  final site = unit['site'];

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 6,
                    shadowColor: Colors.teal.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: unit['photo'] != null && unit['photo'].toString().isNotEmpty
                                ? Image.network(
                                    unit['photo'],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.directions_bus, size: 40, color: Colors.grey),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.directions_bus, size: 40, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Placa: ${unit['plate']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Capacidad: ${unit['capacity']}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sitio: ${site?['name'] ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.teal),
                                tooltip: 'Editar unidad',
                                onPressed: () => _showUnitForm(unit: unit),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: 'Eliminar unidad',
                                onPressed: () => _deleteUnit(unit['id'].toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showUnitForm(),
      icon: const Icon(Icons.add),
      label: const Text('Agregar Unidad'),
      backgroundColor: Colors.teal,
      elevation: 6,
    ),
  );
}

}
