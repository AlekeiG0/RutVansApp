import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/api_service.dart'; // ✅ Laravel y Node aquí
import '../../../widgets/app_scaffold.dart';
import 'repo_ventas.dart';
import 'detallado_ventas.dart';

class FinanzasPage extends StatefulWidget {
  const FinanzasPage({Key? key}) : super(key: key);

  @override
  State<FinanzasPage> createState() => _FinanzasPageState();
}

class _FinanzasPageState extends State<FinanzasPage> {
  double ingresos = 0;
  double egresos = 0;
  double balance = 0;
  List<Map<String, dynamic>> ventasPorDia = [];
  List<Map<String, dynamic>> transacciones = [];

  DateTime? filtroDesde;
  DateTime? filtroHasta;
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => cargarDatos());
    });
  }

  Future<void> cargarDatos() async {
    if (!mounted) return;
    setState(() => cargando = true);

    try {
      final data = await LaravelApiService.getResumen(
        desde: filtroDesde != null ? formatter.format(filtroDesde!) : null,
        hasta: filtroHasta != null ? formatter.format(filtroHasta!) : null,
      );

      if (!mounted) return;
      setState(() {
        ingresos = double.tryParse(data['ingresos'].toString()) ?? 0.0;
        egresos = double.tryParse(data['egresos'].toString()) ?? 0.0;
        balance = double.tryParse(data['balance'].toString()) ?? 0.0;
        ventasPorDia = List<Map<String, dynamic>>.from(data['ventasPorDia']);
        transacciones = List<Map<String, dynamic>>.from(data['transacciones']);
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error cargando datos resumen: $e');
      setState(() => cargando = false);
    }
  }

  void limpiarFiltro() {
    filtroDesde = null;
    filtroHasta = null;
    cargarDatos();
  }

  Future<void> seleccionarFecha(BuildContext context, bool esDesde) async {
    DateTime inicial = esDesde ? (filtroDesde ?? DateTime.now()) : (filtroHasta ?? DateTime.now());

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2024),
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
    final fechaActual = DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(DateTime.now());

    return AppScaffold(
      currentIndex: 1,
      currentDrawerIndex: 1,
appBarTitle: 'Finanzas',
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildEncabezado(fechaActual),
                  const SizedBox(height: 20),
                  _buildTarjetasResumen(),
                  const SizedBox(height: 20),
                  _buildChart(),
                  const SizedBox(height: 10),
                  _buildBotonesReportes(context),
                  const SizedBox(height: 20),
                  _buildFiltroFechas(context),
                  const SizedBox(height: 20),
                  _buildTransaccionesRecientes(),
                ],
              ),
            ),
    );
  }

  Widget _buildEncabezado(String fechaActual) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen Financiero',
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Vista general de ingresos, egresos y ventas',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 8),
          Text('Hoy: $fechaActual',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
          if (filtroDesde != null || filtroHasta != null)
            Text(
              'Filtro activo: ${filtroDesde != null ? formatter.format(filtroDesde!) : ''} - ${filtroHasta != null ? formatter.format(filtroHasta!) : ''}',
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildTarjetasResumen() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _financeCard(Icons.trending_up, ingresos, 'Ingresos', Colors.green),
        _financeCard(Icons.trending_down, egresos, 'Egresos', Colors.red),
        _financeCard(Icons.attach_money, balance, 'Balance', Colors.blue),
      ],
    );
  }

  Widget _financeCard(IconData icon, double monto, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text('\$${monto.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (ventasPorDia.isEmpty) {
      return const Text('Sin datos suficientes para la gráfica');
    }

    final maxY = ventasPorDia
        .map((e) => double.tryParse(e['total'].toString()) ?? 0.0)
        .reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index >= ventasPorDia.length) return const SizedBox();
                  final fecha = DateTime.parse(ventasPorDia[index]['fecha']);
                  return Text(DateFormat('dd/MM').format(fecha),
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text('\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(ventasPorDia.length, (index) {
            final total = double.tryParse(ventasPorDia[index]['total'].toString()) ?? 0.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: total,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBotonesReportes(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Generar Reporte de Ventas'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RepoVentasPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.insert_chart_outlined),
            label: const Text('Ver Reporte Detallado'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DetalladoVentasPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroFechas(BuildContext context) {
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
          icon: const Icon(Icons.clear),
          onPressed: limpiarFiltro,
        ),
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
          Text(value != null ? formatter.format(value) : label,
              style: const TextStyle(color: Colors.black87)),
          const Spacer(),
          const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTransaccionesRecientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Transacciones Recientes',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 10),
        ...transacciones.map((tx) => _transaccionItem(tx)).toList(),
      ],
    );
  }

  Widget _transaccionItem(Map<String, dynamic> tx) {
    DateTime? date =
        tx['created_at'] != null ? DateTime.tryParse(tx['created_at']) : null;
    final fecha = date != null ? formatter.format(date) : '—';
    final monto = double.tryParse(tx['amount'].toString()) ?? 0.0;

    return ListTile(
      leading: const Icon(Icons.attach_money, color: Colors.green),
      title: Text('Folio: ${tx['folio']}'),
      subtitle: Text('Fecha: $fecha'),
      trailing: Text(
        '\$${monto.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      ),
    );
  }
}
