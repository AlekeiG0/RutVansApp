import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_scaffold.dart';

class HorariosPage extends StatefulWidget {
  const HorariosPage({Key? key}) : super(key: key);

  @override
  State<HorariosPage> createState() => _HorariosPageState();
}

class _HorariosPageState extends State<HorariosPage> {
  List<dynamic> _schedules = [];
  List<dynamic> _routeUnits = [];
  bool _loading = true;
  final Map<int, dynamic> _routeUnitsMap = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ScheduleService.getSchedules(),
        ScheduleService.getRouteUnits(),
      ]);
      
      setState(() {
        _schedules = results[0];
        _routeUnits = results[1];
        _routeUnitsMap.clear();
        for (var unit in _routeUnits) {
          _routeUnitsMap[unit['id']] = unit;
        }
        _loading = false;
      });
    } catch (e) {
      _showMessage('Error cargando datos: $e');
      setState(() => _loading = false);
    }
  }

  String _getPlateForSchedule(Map<String, dynamic> schedule) {
    if (schedule['route_unit'] != null && schedule['route_unit']['plate'] != null) {
      return schedule['route_unit']['plate'];
    }
    
    final unit = _routeUnitsMap[schedule['route_unit_id']];
    return unit?['plate'] ?? 'N/A';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showForm({Map<String, dynamic>? schedule}) async {
    final isEditing = schedule != null;
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(
      text: isEditing ? schedule['schedule_date'] : '',
    );
    final timeController = TextEditingController(
      text: isEditing ? schedule['schedule_time'] : '',
    );
    final statusController = TextEditingController(
      text: isEditing ? schedule['status'] : 'activo',
    );

    int? selectedRouteUnitId = isEditing ? schedule['route_unit_id'] : null;
    bool loadingRouteUnits = _routeUnits.isEmpty;
    final colors = _getColors();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingRouteUnits && _routeUnits.isEmpty) {
            ScheduleService.getRouteUnits().then((data) {
              setDialogState(() {
                _routeUnits = data;
                _routeUnitsMap.clear();
                for (var unit in data) {
                  _routeUnitsMap[unit['id']] = unit;
                }
                loadingRouteUnits = false;
              });
            }).catchError((e) {
              setDialogState(() => loadingRouteUnits = false);
              _showMessage('Error cargando unidades: $e');
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEditing ? 'Editar Horario' : 'Nuevo Horario',
              style: TextStyle(color: colors['primary']),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildRouteUnitDropdown(
                      routeUnits: _routeUnits,
                      loading: loadingRouteUnits,
                      selectedId: selectedRouteUnitId,
                      onChanged: (val) => selectedRouteUnitId = val,
                      colors: colors,
                    ),
                    const SizedBox(height: 15),
                    _buildDateField(dateController, colors),
                    const SizedBox(height: 15),
                    _buildTimeField(timeController, colors),
                    const SizedBox(height: 15),
                    _buildStatusDropdown(statusController, colors),
                  ],
                ),
              ),
            ),
            actions: _buildFormActions(
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedRouteUnitId == null) {
                  _showMessage('Seleccione una unidad');
                  return;
                }

                try {
                  if (isEditing) {
                    await ScheduleService.updateSchedule(
                      id: schedule['id'],
                      routeUnitId: selectedRouteUnitId!,
                      scheduleDate: dateController.text,
                      scheduleTime: timeController.text,
                      status: statusController.text,
                    );
                    _showMessage('Horario actualizado');
                  } else {
                    await ScheduleService.createSchedule(
                      routeUnitId: selectedRouteUnitId!,
                      scheduleDate: dateController.text,
                      scheduleTime: timeController.text,
                      status: statusController.text,
                    );
                    _showMessage('Horario creado');
                  }
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _loadInitialData();
                } catch (e) {
                  if (!mounted) return;
                  _showMessage('Error: ${e.toString()}');
                }
              },
              colors: colors,
              isEditing: isEditing,
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteSchedule(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este horario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ScheduleService.deleteSchedule(id);
        setState(() {
          _schedules.removeWhere((schedule) => schedule['id'] == id);
        });
        _showMessage('Horario eliminado');
      } catch (e) {
        _showMessage('Error al eliminar horario: ${e.toString()}');
        await _loadInitialData();
      }
    }
  }

  String _formatDateTime(String date, String time) {
    try {
      final dateTime = DateTime.parse('$date $time');
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return '$date $time';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'activo':
        return Colors.green;
      case 'inactivo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Horarios',
      currentIndex: 3,
      body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: _schedules.isEmpty
                  ? const Center(child: Text('No hay horarios registrados'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _buildScheduleCard(_schedules[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final plate = _getPlateForSchedule(schedule);
    final status = schedule['status'] ?? 'activo';
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unidad: $plate',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_formatDateTime(
              schedule['schedule_date'] ?? 'N/A',
              schedule['schedule_time'] ?? '00:00:00',
            )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showForm(schedule: schedule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteSchedule(schedule['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getColors() {
    return {
      'primary': const Color(0xFF0A3D62),
      'secondary': const Color(0xFF3C6382),
      'danger': const Color(0xFFeb2f06),
    };
  }

  Widget _buildRouteUnitDropdown({
    required List<dynamic> routeUnits,
    required bool loading,
    required int? selectedId,
    required Function(int?) onChanged,
    required Map<String, Color> colors,
  }) {
    return loading
        ? const CircularProgressIndicator()
        : DropdownButtonFormField<int>(
            value: selectedId,
            items: routeUnits.map((unit) => DropdownMenuItem<int>(
              value: unit['id'],
              child: Text(unit['plate'] ?? 'Sin placa'),
            )).toList(),
            onChanged: onChanged,
            decoration: _inputDecoration('Unidad de Ruta', colors),
            validator: (v) => v == null ? 'Seleccione una unidad' : null,
          );
  }

  Widget _buildDateField(TextEditingController controller, Map<String, Color> colors) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
      decoration: _inputDecoration('Fecha', colors),
      validator: (v) => v?.isEmpty ?? true ? 'Ingrese una fecha' : null,
    );
  }

  Widget _buildTimeField(TextEditingController controller, Map<String, Color> colors) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          controller.text = 
              "${time.hour.toString().padLeft(2, '0')}:"
              "${time.minute.toString().padLeft(2, '0')}:00";
        }
      },
      decoration: _inputDecoration('Hora', colors),
      validator: (v) => v?.isEmpty ?? true ? 'Ingrese una hora' : null,
    );
  }

  Widget _buildStatusDropdown(TextEditingController controller, Map<String, Color> colors) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : 'activo',
      items: const [
        DropdownMenuItem<String>(
          value: 'activo',
          child: Text('Activo'),
        ),
        DropdownMenuItem<String>(
          value: 'inactivo',
          child: Text('Inactivo'),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          controller.text = val;
        }
      },
      decoration: _inputDecoration('Estado', colors),
      validator: (v) => v?.isEmpty ?? true ? 'Seleccione un estado' : null,
    );
  }

  InputDecoration _inputDecoration(String label, Map<String, Color> colors) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors['secondary']),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors['secondary']!)),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colors['primary']!)),
    );
  }

  List<Widget> _buildFormActions({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required Map<String, Color> colors,
    bool isEditing = false,
  }) {
    return [
      TextButton(
        onPressed: onCancel,
        child: Text('Cancelar', style: TextStyle(color: colors['danger'])),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onConfirm,
        child: Text(isEditing ? 'Guardar' : 'Crear'),
      ),
    ];
  }
}