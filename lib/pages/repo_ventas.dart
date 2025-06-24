import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../widgets/App_Scaffold.dart';

class RepoVentasPage extends StatefulWidget {
  const RepoVentasPage({super.key});

  @override
  State<RepoVentasPage> createState() => _RepoVentasPageState();
}

class _RepoVentasPageState extends State<RepoVentasPage> {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final DateFormat mostrar = DateFormat('dd/MM/yyyy');

  DateTime? filtroDesde;
  DateTime? filtroHasta;
  bool cargando = false;

  double total = 0;
  double promedio = 0;
  int transacciones = 0;

  List<Map<String, dynamic>> balanceHistorico = [];
  List<Map<String, dynamic>> topRutas = [];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    filtroHasta = hoy;
    filtroDesde = hoy.subtract(const Duration(days: 30));
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    if (filtroDesde == null || filtroHasta == null) return;

    setState(() => cargando = true);

    final desdeStr = formatter.format(filtroDesde!);
    final hastaStr = formatter.format(filtroHasta!);

    try {
      final resumen = await ApiService.getVentasPeriodo(desde: desdeStr, hasta: hastaStr);
      final balance = await ApiService.getBalanceHistorico(
        periodo: 'daily',
        desde: desdeStr,
        hasta: hastaStr,
      );
      final rutas = await ApiService.getTopRutas(desde: desdeStr, hasta: hastaStr);

      setState(() {
        total = (resumen['total'] as num).toDouble();
        promedio = (resumen['promedio'] as num).toDouble();
        transacciones = (resumen['transacciones'] as num).toInt();

        balanceHistorico = balance;
        topRutas = rutas;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
    }

    setState(() => cargando = false);
  }

  Future<void> seleccionarFecha(BuildContext context, bool esDesde) async {
    final inicial = esDesde ? filtroDesde! : filtroHasta!;
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esDesde) {
          filtroDesde = fecha;
        } else {
          filtroHasta = fecha;
        }
      });
      cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 20),
                  _buildDateFilters(),
                  const SizedBox(height: 20),
                  _buildResumenFinanciero(),
                  const SizedBox(height: 20),
                  _buildGraficoBalance(),
                  const SizedBox(height: 20),
                  _buildTopRutas(),
                ],
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Reporte General de Ventas',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateFilters() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => seleccionarFecha(context, true),
            child: _dateBox('Desde', filtroDesde),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => seleccionarFecha(context, false),
            child: _dateBox('Hasta', filtroHasta),
          ),
        ),
        IconButton(
          onPressed: () {
            final hoy = DateTime.now();
            setState(() {
              filtroHasta = hoy;
              filtroDesde = hoy.subtract(const Duration(days: 30));
            });
            cargarDatos();
          },
          icon: const Icon(Icons.refresh),
        )
      ],
    );
  }

  Widget _dateBox(String label, DateTime? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          Text(value != null ? mostrar.format(value) : label,
              style: const TextStyle(color: Colors.black87)),
          const Spacer(),
          const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildResumenFinanciero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _resumenItem('Total', '\$${total.toStringAsFixed(2)}', Colors.blue),
          _resumenItem('Transacciones', '$transacciones', Colors.green),
          _resumenItem('Promedio', '\$${promedio.toStringAsFixed(2)}', Colors.orange),
        ],
      ),
    );
  }

  Widget _resumenItem(String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.attach_money, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGraficoBalance() {
    if (balanceHistorico.isEmpty) {
      return const Text('No hay datos suficientes para mostrar el gráfico.');
    }

    final spots = balanceHistorico.asMap().entries.map((entry) {
      final index = entry.key;
      final monto = (entry.value['balance'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), monto);
    }).toList();

    final maxY = spots.map((e) => e.y).fold(0.0, (a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingresos por Día',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRutas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rutas más vendidas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...topRutas.map((ruta) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ruta['nombre'],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(ruta['monto'], style: const TextStyle(color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: ruta['porcentaje'] ?? 0.0,
                      backgroundColor: Colors.grey[200],
                      color: Colors.orange,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
