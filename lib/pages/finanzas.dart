import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'repo_ventas.dart';
import 'detallado_ventas.dart';
import '../widgets/App_Scaffold.dart';

// 🔹 Modelo de transacción
class Transaccion {
  final String titulo;
  final String fecha;
  final String hora;
  final double monto;
  final bool esIngreso;
  final IconData icono;

  Transaccion({
    required this.titulo,
    required this.fecha,
    required this.hora,
    required this.monto,
    required this.esIngreso,
    required this.icono,
  });
}

// 🔹 Tarjeta general reutilizable
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
      padding: const EdgeInsets.all(12),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}

// 🔹 Tarjeta individual (Ingresos, Egresos, Balance)
class FinanceCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const FinanceCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              )),
        ],
      ),
    );
  }
}

// 🔸 Página principal de Finanzas
class FinanzasPage extends StatelessWidget {
  const FinanzasPage({super.key});

  // 🔸 Datos simulados de transacciones
  static final List<Transaccion> _transacciones = [
    Transaccion(
      titulo: 'Venta de boletos',
      fecha: 'Hoy',
      hora: '10:30 AM',
      monto: 450.00,
      esIngreso: true,
      icono: Icons.directions_bus,
    ),
    Transaccion(
      titulo: 'Combustible',
      fecha: 'Ayer',
      hora: '3:15 PM',
      monto: 1200.00,
      esIngreso: false,
      icono: Icons.local_gas_station,
    ),
    Transaccion(
      titulo: 'Mantenimiento',
      fecha: 'Ayer',
      hora: '9:00 AM',
      monto: 850.00,
      esIngreso: false,
      icono: Icons.build,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 1,
      currentDrawerIndex: 1, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildSalesChart(),
                  const SizedBox(height: 20),
                  _buildRecentTransactions(),
                  const SizedBox(height: 20),
                  _buildSalesReportButton(context),
                  const SizedBox(height: 10),
                  _buildDetailedReportButton(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟧 Encabezado
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen Financiero',
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('Vista general de ingresos, egresos y ventas',
              style: TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }

  // 🟩 Tarjetas resumen
  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Expanded(
          child: FinanceCard(
            icon: Icons.trending_up,
            value: '\$100000.00',
            label: 'Ingresos',
            color: Colors.green,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: FinanceCard(
            icon: Icons.trending_down,
            value: '\$300.00',
            label: 'Egresos',
            color: Colors.red,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: FinanceCard(
            icon: Icons.attach_money,
            value: '\$99700.00',
            label: 'Balance',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  // 🟦 Historial de ventas - gráfico de barras
  Widget _buildSalesChart() {
    final List<double> ventasUltimos7Dias = [12000, 11300, 870, 950, 820, 680, 12300];
    final dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final double maxY = ventasUltimos7Dias.reduce((a, b) => a > b ? a : b) * 1.2;

    return CustomCard(
      title: 'Historial de Ventas (Últimos 7 días)',
      content: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(dias[value.toInt() % dias.length]);
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text('\$${value.toInt()}');
                  },
                  reservedSize: 40,
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              ventasUltimos7Dias.length,
              (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: ventasUltimos7Dias[index],
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🟨 Transacciones recientes
  Widget _buildRecentTransactions() {
    return CustomCard(
      title: 'Transacciones Recientes',
      content: Column(
        children: _transacciones.map((tx) => _buildTransactionItem(tx)).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(Transaccion tx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tx.esIngreso ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tx.icono, color: tx.esIngreso ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${tx.fecha}, ${tx.hora}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '\$${tx.monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.esIngreso ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // 🟧 Botón: Generar reporte
  Widget _buildSalesReportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SalesReportPage()),
          );
        },
        child: const Text(
          'Generar Reporte de Ventas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 🟨 Botón: Ver reporte detallado
  Widget _buildDetailedReportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DetailedSalesReportPage()),
          );
        },
        child: const Text(
          'Ver Reporte Detallado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
