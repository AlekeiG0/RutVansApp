import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'NotificacionesPage.dart';
import 'package:flutter/foundation.dart';
import '../widgets/App_Scaffold.dart';


class GestionIncidenciasPage extends StatelessWidget {
  const GestionIncidenciasPage({super.key});

  @override
  Widget build(BuildContext context) {
      return AppScaffold(
    currentIndex: 0,
    currentDrawerIndex: 7, 
      body: const IncidenciasBody(),
    );
  }

  static void _showAddIncidenteDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    String tipoSeleccionado = 'Accidente';
    String gravedadSeleccionada = 'Media';
    DateTime fechaSeleccionada = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Reporte de Incidencia'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Este campo es requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Este campo es requerido' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tipoSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de incidencia',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Accidente', 'Mecánica', 'Pasajero', 'Otro']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => tipoSeleccionado = value!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gravedadSeleccionada,
                  decoration: const InputDecoration(
                    labelText: 'Gravedad',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Baja', 'Media', 'Alta']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => gravedadSeleccionada = value!,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(fechaSeleccionada)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (selectedDate != null) {
                      fechaSeleccionada = selectedDate;
                      Navigator.pop(context);
                      _showAddIncidenteDialog(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final nuevaIncidencia = Incidente(
                  titulo: tituloController.text,
                  descripcion: descripcionController.text,
                  tipo: tipoSeleccionado,
                  estado: 'En revisión',
                  gravedad: gravedadSeleccionada,
                  fecha: fechaSeleccionada,
                );

                Provider.of<IncidenciasProvider>(context, listen: false)
                    .agregarIncidente(nuevaIncidencia);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incidencia reportada con éxito')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('images/logo.png', height: 40),
          const SizedBox(width: 10),
          const Text('Gestión de Incidencias',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificacionesPage()),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.account_circle, color: Colors.white, size: 28),
        ],
      ),
    );
  }
}

class IncidenciasBody extends StatelessWidget {
  const IncidenciasBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IncidenciasHeader(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const QuickActionsRow(),
                const SizedBox(height: 20),
                Consumer<IncidenciasProvider>(
                  builder: (context, provider, _) {
                    if (provider.listaIncidencias.isEmpty) {
                      return const CustomCard(
                        title: 'Incidencias Recientes',
                        content: Center(
                          child: Text('No hay incidencias recientes',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }

                    return CustomCard(
                      title: 'Incidencias Recientes',
                      content: Column(
                        children: provider.listaIncidencias
                            .take(5) // Mostrar solo las 5 más recientes
                            .map((incidencia) => IncidenteItem(incidencia: incidencia))
                            .toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const EstadisticasCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IncidenciasHeader extends StatelessWidget {
  const IncidenciasHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Consumer<IncidenciasProvider>(
        builder: (context, provider, _) {
          final stats = provider.estadisticas;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gestión de Incidencias',
                  style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text('Registro y seguimiento de siniestros y problemas en rutas',
                  style: TextStyle(fontSize: 14, color: Colors.white)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatCard(value: stats.abiertas.toString(), label: 'Abiertas', color: Colors.red),
                  _StatCard(value: stats.enProceso.toString(), label: 'En proceso', color: Colors.amber),
                  _StatCard(value: stats.resueltas.toString(), label: 'Resueltas', color: Colors.green),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionButton(
          icon: Icons.report,
          label: 'Reportar',
          color: Colors.red,
          onTap: () => GestionIncidenciasPage._showAddIncidenteDialog(context),
        ),
        _ActionButton(
          icon: Icons.search,
          label: 'Buscar',
          color: Colors.blue,
          onTap: () => _mostrarBusqueda(context),
        ),
        _ActionButton(
          icon: Icons.filter_alt,
          label: 'Filtrar',
          color: Colors.green,
          onTap: () => _mostrarFiltros(context),
        ),
        _ActionButton(
          icon: Icons.bar_chart,
          label: 'Estadísticas',
          color: Colors.purple,
          onTap: () => _mostrarEstadisticas(context),
        ),
      ],
    );
  }

  void _mostrarBusqueda(BuildContext context) {
    // Implementar búsqueda
  }

  void _mostrarFiltros(BuildContext context) {
    // Implementar filtros
  }

  void _mostrarEstadisticas(BuildContext context) {
    // Implementar estadísticas detalladas
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final Widget content;

  const CustomCard({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

class IncidenteItem extends StatelessWidget {
  final Incidente incidencia;

  const IncidenteItem({
    super.key,
    required this.incidencia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(incidencia.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEstadoColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(incidencia.estado,
                    style: TextStyle(color: _getEstadoColor(), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(DateFormat('dd/MM/yyyy').format(incidencia.fecha),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.category, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(incidencia.tipo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getGravedadColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getGravedadColor().withOpacity(0.3)),
                ),
                child: Text(incidencia.gravedad,
                    style: TextStyle(color: _getGravedadColor(), fontSize: 12)),
              ),
            ],
          ),
       
        ],
      ),
    );
  }

  Color _getEstadoColor() {
    switch (incidencia.estado) {
      case 'En revisión':
        return Colors.orange;
      case 'En proceso':
        return Colors.blue;
      case 'Resuelto':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getGravedadColor() {
    switch (incidencia.gravedad) {
      case 'Alta':
        return Colors.red;
      case 'Media':
        return Colors.orange;
      case 'Baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class EstadisticasCard extends StatelessWidget {
  const EstadisticasCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncidenciasProvider>(
      builder: (context, provider, _) {
        final stats = provider.estadisticasPorTipo;

        return CustomCard(
          title: 'Estadísticas de Incidencias',
          content: SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: stats.accidentes.toDouble(),
                            color: Colors.orange,
                            title: '${stats.accidentes}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: stats.mecanicas.toDouble(),
                            color: Colors.red,
                            title: '${stats.mecanicas}',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: stats.pasajeros.toDouble(),
                            color: Colors.blue,
                            title: '${stats.pasajeros}',
                            radius: 40,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: stats.otros.toDouble(),
                            color: Colors.green,
                            title: '${stats.otros}',
                            radius: 30,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LegendItem(color: Colors.orange, text: 'Accidentes'),
                        LegendItem(color: Colors.red, text: 'Mecánicas'),
                        LegendItem(color: Colors.blue, text: 'Pasajeros'),
                        LegendItem(color: Colors.green, text: 'Otros'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({
    super.key,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// Modelo de datos
class Incidente {
  final String titulo;
  final String descripcion;
  final String tipo;
  final String estado;
  final String gravedad;
  final DateTime fecha;

  Incidente({
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.estado,
    required this.gravedad,
    required this.fecha,
  });
}

// Provider para manejar el estado
class IncidenciasProvider with ChangeNotifier {
  final List<Incidente> _listaIncidencias = [];

  List<Incidente> get listaIncidencias => _listaIncidencias;

  void agregarIncidente(Incidente incidencia) {
    _listaIncidencias.insert(0, incidencia);
    notifyListeners();
  }

  // Estadísticas
  Estadisticas get estadisticas {
    return Estadisticas(
      abiertas: _listaIncidencias.where((i) => i.estado == 'En revisión').length,
      enProceso: _listaIncidencias.where((i) => i.estado == 'En proceso').length,
      resueltas: _listaIncidencias.where((i) => i.estado == 'Resuelto').length,
    );
  }

  // Estadísticas por tipo
  EstadisticasPorTipo get estadisticasPorTipo {
    return EstadisticasPorTipo(
      accidentes: _listaIncidencias.where((i) => i.tipo == 'Accidente').length,
      mecanicas: _listaIncidencias.where((i) => i.tipo == 'Mecánica').length,
      pasajeros: _listaIncidencias.where((i) => i.tipo == 'Pasajero').length,
      otros: _listaIncidencias.where((i) => i.tipo == 'Otro').length,
    );
  }
}

class Estadisticas {
  final int abiertas;
  final int enProceso;
  final int resueltas;

  Estadisticas({
    required this.abiertas,
    required this.enProceso,
    required this.resueltas,
  });
}

class EstadisticasPorTipo {
  final int accidentes;
  final int mecanicas;
  final int pasajeros;
  final int otros;

  EstadisticasPorTipo({
    required this.accidentes,
    required this.mecanicas,
    required this.pasajeros,
    required this.otros,
  });
}