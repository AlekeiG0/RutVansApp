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

  int mesSeleccionado = DateTime.now().month;
  int anioSeleccionado = DateTime.now().year;

  List<Map<String, dynamic>> balanceHistorico = [];
  List<Map<String, dynamic>> topRutas = [];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _calcularFechas(hoy.year, hoy.month);
  }

  void _calcularFechas(int anio, int mes) {
    final desde = DateTime(anio, mes - 1, 16);
    final hasta = DateTime(anio, mes, 15);

    setState(() {
      mesSeleccionado = mes;
      anioSeleccionado = anio;
      filtroDesde = desde;
      filtroHasta = hasta;
    });

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
                  _buildMonthSelector(),
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
    final periodo = filtroDesde != null && filtroHasta != null
        ? '${mostrar.format(filtroDesde!)} - ${mostrar.format(filtroHasta!)}'
        : '';
    return Text(
      'Reporte mensual de Ventas\n$periodo',
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<int>(
            value: mesSeleccionado,
            onChanged: (nuevoMes) {
              if (nuevoMes != null) {
                _calcularFechas(anioSeleccionado, nuevoMes);
              }
            },
            isExpanded: true,
            items: List.generate(12, (index) {
              final mes = index + 1;
              final nombreMes = DateFormat.MMMM('es_MX').format(DateTime(0, mes));
              return DropdownMenuItem(
                value: mes,
                child: Text(nombreMes[0].toUpperCase() + nombreMes.substring(1)),
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            final hoy = DateTime.now();
            _calcularFechas(hoy.year, hoy.month);
          },
        ),
      ],
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

    final semanas = List.generate(4, (_) => 0.0);

    for (var dato in balanceHistorico) {
      final fecha = DateTime.parse(dato['fecha']);
      final monto = (dato['balance'] as num?)?.toDouble() ?? 0.0;
      final dia = fecha.day;

      if (dia >= 16 && dia <= 22) {
        semanas[0] += monto;
      } else if (dia >= 23 && dia <= 29) {
        semanas[1] += monto;
      } else if (dia >= 30 || dia <= 6) {
        semanas[2] += monto;
      } else if (dia >= 7 && dia <= 15) {
        semanas[3] += monto;
      }
    }

    final spots = List.generate(4, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: semanas[i],
              width: 20,
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(show: false),
            ),
          ],
        ));

    final mayor = semanas.reduce((a, b) => a > b ? a : b);
    final menor = semanas.reduce((a, b) => a < b ? a : b);
    final indexMayor = semanas.indexOf(mayor);
    final indexMenor = semanas.indexOf(menor);

    const etiquetas = ['16–22', '23–29', '30–6', '7–15'];

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
          const Text('Ingresos semanales del periodo 16–15',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text(
            'Se agrupan los ingresos en 4 bloques por semana. Esto facilita la comparación del rendimiento del mes.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: spots,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(etiquetas[value.toInt()],
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '📈 Semana con más ingresos: ${etiquetas[indexMayor]} → \$${mayor.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Colors.green),
          ),
          Text(
            '📉 Semana más baja: ${etiquetas[indexMenor]} → \$${menor.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Colors.red),
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
          ...topRutas.map((ruta) {
            final String nombre = ruta['nombre']?.toString().trim() ?? 'Sin nombre';
            final double monto = double.tryParse(
                  ruta['monto'].toString().replaceAll(RegExp(r'[^\d.]'), ''),
                ) ??
                0.0;
            final double porcentaje = (ruta['porcentaje'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text(
                        '\$${monto.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: porcentaje,
                    backgroundColor: Colors.grey[200],
                    color: Colors.orange,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Representa ${(porcentaje * 100).toStringAsFixed(1)}% del total',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

}