import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../services/schedule_service.dart';
import '../../widgets/app_scaffold.dart';

class HorariosPage extends StatefulWidget {
  const HorariosPage({Key? key}) : super(key: key);

  @override
  State<HorariosPage> createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  List<Map<String, dynamic>> horarios = [];
  List<String> placasUnidades = [
    'YC895MX',
    'YC789MX', 
    'YC456MX',
    'YC321MX',
    'YC987MX',
    'YC654MX'
  ];
  bool isLoading = false;

  final List<String> destinos = [
    'Maxcanu',
    'Merida',
    'Opichen',
    'Uman',
    'Chochola',
    'Calkini',
    'Becal',
    'Hecelchakan',
    'Tenabo',
    'Pomuch'
  ];

  @override
  void initState() {
    super.initState();
    _loadHorarios();
  }

  // MÉTODO ACTUALIZADO PARA FORZAR REFRESCO
  Future<void> _refreshHorarios() async {
    await _loadHorarios();
  }

  // GUARDAR HORARIOS EN SHARED PREFERENCES
  Future<void> _saveHorarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final horariosJson = jsonEncode(horarios);
      await prefs.setString('horarios', horariosJson);
      print('✅ Horarios guardados: ${horarios.length}');
    } catch (e) {
      print('❌ Error guardando horarios: $e');
    }
  }

  // CARGAR HORARIOS DESDE SHARED PREFERENCES - ACTUALIZADO
  Future<void> _loadHorarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final horariosString = prefs.getString('horarios');
      
      if (horariosString != null && horariosString.isNotEmpty) {
        final List<dynamic> horariosList = jsonDecode(horariosString);
        
        // FORZAR ACTUALIZACIÓN DEL ESTADO
        if (mounted) {
          setState(() {
            horarios = List<Map<String, dynamic>>.from(horariosList);
          });
        }
        print('✅ Horarios cargados: ${horarios.length}');
      } else {
        if (mounted) {
          setState(() {
            horarios = [];
          });
        }
        print('ℹ️ No hay horarios guardados');
      }
    } catch (e) {
      print('❌ Error cargando horarios: $e');
      if (mounted) {
        setState(() {
          horarios = [];
        });
      }
    }
  }

  // GUARDAR IMAGEN EN SHARED PREFERENCES
  Future<void> _saveImageForHorario(String horarioId, String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('imagen_$horarioId', imagePath);
      print('✅ Imagen guardada para horario: $horarioId');
    } catch (e) {
      print('❌ Error guardando imagen: $e');
    }
  }

  // CARGAR IMAGEN DESDE SHARED PREFERENCES
  Future<File?> _loadImageForHorario(String horarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('imagen_$horarioId');
      if (imagePath != null && File(imagePath).existsSync()) {
        return File(imagePath);
      }
    } catch (e) {
      print('❌ Error cargando imagen: $e');
    }
    return null;
  }

  void _mostrarModalCrearHorario() {
    String? _placaTempSeleccionada;
    DateTime _fechaSeleccionada = DateTime.now();
    TimeOfDay _horaSeleccionada = TimeOfDay.now();
    String _statusSeleccionado = 'active';
    
    final _nombreTempController = TextEditingController();
    String? _origenTempSeleccionado;
    String? _destinoTempSeleccionado;
    File? _imagenTempSeleccionada;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Crear Nuevo Horario Completo"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "Información del Conductor",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() => _imagenTempSeleccionada = File(pickedFile.path));
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _imagenTempSeleccionada != null
                        ? FileImage(_imagenTempSeleccionada!)
                        : const AssetImage('assets/images/default_driver.png') as ImageProvider,
                    child: _imagenTempSeleccionada == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Toca para cambiar foto",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _nombreTempController,
                  decoration: const InputDecoration(
                    labelText: "Nombre del Conductor",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // CAMPO ORIGEN COMO DROPDOWN
                DropdownButtonFormField<String>(
                  value: _origenTempSeleccionado,
                  decoration: const InputDecoration(
                    labelText: "Origen",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: destinos.map((origen) {
                    return DropdownMenuItem(
                      value: origen,
                      child: Text(origen),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _origenTempSeleccionado = value),
                ),
                const SizedBox(height: 16),

                // CAMPO DESTINO COMO DROPDOWN
                DropdownButtonFormField<String>(
                  value: _destinoTempSeleccionado,
                  decoration: const InputDecoration(
                    labelText: "Destino",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: destinos.map((destino) {
                    return DropdownMenuItem(
                      value: destino,
                      child: Text(destino),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _destinoTempSeleccionado = value),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Información del Horario",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CAMPO PLACA COMO DROPDOWN
                DropdownButtonFormField<String>(
                  value: _placaTempSeleccionada,
                  decoration: const InputDecoration(
                    labelText: "Placa de la Unidad",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                  items: placasUnidades.map((placa) {
                    return DropdownMenuItem<String>(
                      value: placa,
                      child: Text("Placa: $placa"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _placaTempSeleccionada = value),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text("Fecha"),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(_fechaSeleccionada)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: _fechaSeleccionada,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (fecha != null) {
                            setState(() => _fechaSeleccionada = fecha);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text("Hora"),
                        subtitle: Text(_horaSeleccionada.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: _horaSeleccionada,
                          );
                          if (hora != null) {
                            setState(() => _horaSeleccionada = hora);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                DropdownButtonFormField<String>(
                  value: _statusSeleccionado,
                  decoration: const InputDecoration(
                    labelText: "Estado del Horario",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.circle),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'active',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Activo'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Inactivo'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _statusSeleccionado = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: _placaTempSeleccionada == null ? null : () async {
                try {
                  final horarioId = DateTime.now().millisecondsSinceEpoch.toString();
                  
                  // Guardar imagen si se seleccionó una
                  if (_imagenTempSeleccionada != null) {
                    await _saveImageForHorario(horarioId, _imagenTempSeleccionada!.path);
                  }

                  // Crear nuevo horario localmente
                  final nuevoHorario = {
                    'id': horarioId,
                    'placa': _placaTempSeleccionada,
                    'schedule_date': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
                    'schedule_time': _horaSeleccionada.format(context),
                    'status': _statusSeleccionado,
                    'conductor': _nombreTempController.text,
                    'origen': _origenTempSeleccionado,
                    'destino': _destinoTempSeleccionado,
                    'has_image': _imagenTempSeleccionada != null,
                  };

                  // ACTUALIZAR INMEDIATAMENTE EL ESTADO
                  if (mounted) {
                    setState(() {
                      horarios.add(nuevoHorario);
                    });
                  }
                  
                  // GUARDAR HORARIOS EN STORAGE
                  await _saveHorarios();
                  
                  Navigator.pop(context);
                  
                  // FORZAR REFRESCO COMPLETO DE LA VISTA
                  _refreshHorarios();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Horario creado correctamente')),
                  );
                } catch (e) {
                  print('Error al crear horario: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear horario: $e')),
                  );
                }
              },
              child: const Text("Crear Horario Completo"),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetallesHorario(Map<String, dynamic> horario) async {
    final status = horario['status'] ?? 'inactive';
    final formattedDate = horario['schedule_date'] ?? 'N/A';
    final formattedTime = horario['schedule_time'] ?? 'N/A';
    final placa = horario['placa'] ?? 'N/A';
    final isActive = status == 'active' || status == 'activo';

    // Cargar imagen específica para este horario
    final File? imagenHorario = await _loadImageForHorario(horario['id']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Detalles del Horario"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: imagenHorario != null
                            ? FileImage(imagenHorario)
                            : const AssetImage('assets/images/default_conductor.png') as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              horario['conductor']?.isEmpty ?? true 
                                  ? 'Conductor no asignado' 
                                  : horario['conductor'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Origen: ${horario['origen'] ?? 'No definido'}",
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Destino: ${horario['destino'] ?? 'No definido'}",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text("🚌 Información del Horario", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("• Placa: $placa", style: const TextStyle(fontSize: 14)),
              Text("• Conductor: ${horario['conductor'] ?? 'No asignado'}", style: const TextStyle(fontSize: 14)),
              Text("• Origen: ${horario['origen'] ?? 'No definido'}", style: const TextStyle(fontSize: 14)),
              Text("• Destino: ${horario['destino'] ?? 'No definido'}", style: const TextStyle(fontSize: 14)),
              Text("• Fecha: $formattedDate", style: const TextStyle(fontSize: 14)),
              Text("• Hora: $formattedTime", style: const TextStyle(fontSize: 14)),
              Text("• Estado: ${isActive ? 'Activo' : 'Inactivo'}", 
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _editarHorario(horario),
            child: const Text("Editar"),
          ),
          TextButton(
            onPressed: () => _eliminarHorario(horario),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _editarHorario(Map<String, dynamic> horario) {
    Navigator.pop(context);
    
    String? _placaTempSeleccionada = horario['placa'];
    DateTime _fechaSeleccionada = DateTime.now();
    TimeOfDay _horaSeleccionada = TimeOfDay.now();
    String _statusSeleccionado = horario['status'] ?? 'active';

    if (_statusSeleccionado == 'activo') {
      _statusSeleccionado = 'active';
    } else if (_statusSeleccionado == 'inactivo') {
      _statusSeleccionado = 'inactive';
    }

    if (horario['schedule_date'] != null) {
      try {
        _fechaSeleccionada = DateFormat('yyyy-MM-dd').parse(horario['schedule_date']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    if (horario['schedule_time'] != null) {
      try {
        final timeParts = horario['schedule_time'].split(':');
        _horaSeleccionada = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } catch (e) {
        print('Error parsing time: $e');
      }
    }

    // Para editar también agregamos los campos de origen y destino
    String? _origenTempSeleccionado = horario['origen'];
    String? _destinoTempSeleccionado = horario['destino'];
    final _nombreTempController = TextEditingController(text: horario['conductor'] ?? '');
    File? _imagenTempSeleccionada;

    // Cargar imagen existente para este horario
    _loadImageForHorario(horario['id']).then((image) {
      if (image != null) {
        if (mounted) {
          setState(() {
            _imagenTempSeleccionada = image;
          });
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Editar Horario Completo"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "Información del Conductor",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() => _imagenTempSeleccionada = File(pickedFile.path));
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: _imagenTempSeleccionada != null
                        ? FileImage(_imagenTempSeleccionada!)
                        : const AssetImage('assets/images/default_driver.png') as ImageProvider,
                    child: _imagenTempSeleccionada == null
                        ? const Icon(Icons.add_a_photo, color: Colors.white, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Toca para cambiar foto",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _nombreTempController,
                  decoration: const InputDecoration(
                    labelText: "Nombre del Conductor",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // ORIGEN EN EDITAR
                DropdownButtonFormField<String>(
                  value: _origenTempSeleccionado,
                  decoration: const InputDecoration(
                    labelText: "Origen",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: destinos.map((origen) {
                    return DropdownMenuItem(
                      value: origen,
                      child: Text(origen),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _origenTempSeleccionado = value),
                ),
                const SizedBox(height: 16),

                // DESTINO EN EDITAR
                DropdownButtonFormField<String>(
                  value: _destinoTempSeleccionado,
                  decoration: const InputDecoration(
                    labelText: "Destino",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: destinos.map((destino) {
                    return DropdownMenuItem(
                      value: destino,
                      child: Text(destino),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _destinoTempSeleccionado = value),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "Información del Horario",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // PLACA EN EDITAR
                DropdownButtonFormField<String>(
                  value: _placaTempSeleccionada,
                  decoration: const InputDecoration(
                    labelText: "Placa de la Unidad",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                  items: placasUnidades.map((placa) {
                    return DropdownMenuItem<String>(
                      value: placa,
                      child: Text("Placa: $placa"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _placaTempSeleccionada = value),
                ),
                const SizedBox(height: 16),
                
                ListTile(
                  title: const Text("Fecha"),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(_fechaSeleccionada)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _fechaSeleccionada,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (fecha != null) {
                      setState(() => _fechaSeleccionada = fecha);
                    }
                  },
                ),
                ListTile(
                  title: const Text("Hora"),
                  subtitle: Text(_horaSeleccionada.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final hora = await showTimePicker(
                      context: context,
                      initialTime: _horaSeleccionada,
                    );
                    if (hora != null) {
                      setState(() => _horaSeleccionada = hora);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _statusSeleccionado,
                  decoration: const InputDecoration(labelText: "Estado"),
                  items: [
                    DropdownMenuItem(value: 'active', child: Text('Activo')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
                  ],
                  onChanged: (value) => setState(() => _statusSeleccionado = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Guardar nueva imagen si se seleccionó una
                  if (_imagenTempSeleccionada != null) {
                    await _saveImageForHorario(horario['id'], _imagenTempSeleccionada!.path);
                  }

                  // Actualizar el horario localmente
                  final index = horarios.indexWhere((h) => h['id'] == horario['id']);
                  if (index != -1) {
                    if (mounted) {
                      setState(() {
                        horarios[index] = {
                          ...horarios[index],
                          'placa': _placaTempSeleccionada,
                          'schedule_date': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
                          'schedule_time': _horaSeleccionada.format(context),
                          'status': _statusSeleccionado,
                          'conductor': _nombreTempController.text,
                          'origen': _origenTempSeleccionado,
                          'destino': _destinoTempSeleccionado,
                          'has_image': _imagenTempSeleccionada != null,
                        };
                      });
                    }
                    
                    // GUARDAR HORARIOS ACTUALIZADOS
                    await _saveHorarios();
                    
                    // FORZAR REFRESCO COMPLETO DE LA VISTA
                    _refreshHorarios();
                  }
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Horario actualizado correctamente')),
                  );
                } catch (e) {
                  print('Error al editar horario: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar horario: $e')),
                  );
                }
              },
              child: const Text("Guardar Cambios"),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarHorario(Map<String, dynamic> horario) {
    Navigator.pop(context);
    
    final placa = horario['placa'] ?? 'N/A';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: Text("¿Estás seguro de que quieres eliminar el horario de la placa $placa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              if (mounted) {
                setState(() {
                  horarios.removeWhere((h) => h['id'] == horario['id']);
                });
              }
              
              // GUARDAR HORARIOS ACTUALIZADOS DESPUÉS DE ELIMINAR
              await _saveHorarios();
              
              // FORZAR REFRESCO COMPLETO DE LA VISTA
              _refreshHorarios();
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Horario eliminado correctamente')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Horarios de Unidades",
      body: RefreshIndicator(
        onRefresh: _refreshHorarios,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _mostrarModalCrearHorario,
                icon: const Icon(Icons.add),
                label: const Text("Crear Nuevo Horario Completo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (horarios.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          "No hay horarios creados",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    
                    ...horarios.map((horario) {
                      final status = horario['status'] ?? 'inactive';
                      final isActive = status == 'active' || status == 'activo';
                      final color = isActive ? Colors.green : Colors.red;
                      final placa = horario['placa'] ?? 'N/A';
                      
                      return FutureBuilder<File?>(
                        future: _loadImageForHorario(horario['id']),
                        builder: (context, snapshot) {
                          final imagenHorario = snapshot.data;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: imagenHorario != null
                                    ? FileImage(imagenHorario)
                                    : const AssetImage('assets/images/default_conductor.png') as ImageProvider,
                              ),
                              title: Text(
                                horario['conductor']?.isEmpty ?? true 
                                    ? "Placa: $placa" 
                                    : horario['conductor'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Placa: $placa"),
                                  Text("${horario['origen'] ?? 'No definido'} → ${horario['destino'] ?? 'No definido'}"),
                                  Text(
                                    "Estado: ${isActive ? 'Activo' : 'Inactivo'}",
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.circle, color: color, size: 14),
                              onTap: () => _mostrarDetallesHorario(horario),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}