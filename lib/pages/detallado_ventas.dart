import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/App_Scaffold.dart';

class DetailedSalesReportPage extends StatefulWidget {
  const DetailedSalesReportPage({super.key});

  @override
  State<DetailedSalesReportPage> createState() => _DetailedSalesReportPageState();
}

class _DetailedSalesReportPageState extends State<DetailedSalesReportPage> {
  DateTime fechaSeleccionada = DateTime(2023, 5, 15);
  final DateFormat formatter = DateFormat('dd/MM/yyyy');

  // Simulaciones de ventas por fecha
  final Map<String, List<Map<String, dynamic>>> ventasPorFecha = {
    '15/05/2023': [
      {'hora': '10:00 AM', 'ruta': 'Lima - Arequipa', 'monto': 150.0},
      {'hora': '12:30 PM', 'ruta': 'Lima - Trujillo', 'monto': 230.0},
      {'hora': '4:00 PM', 'ruta': 'Lima - Chiclayo', 'monto': 180.0},
    ],
    '16/05/2023': [],
  };

  @override
  Widget build(BuildContext context) {
    final String fechaStr = formatter.format(fechaSeleccionada);
    final ventasHoy = ventasPorFecha[fechaStr] ?? [];

    final double totalHoy = ventasHoy.fold(0.0, (sum, v) => sum + v['monto']);
    final int totalTransacciones = ventasHoy.length;
    final double promedio = totalTransacciones == 0 ? 0 : totalHoy / totalTransacciones;

    return AppScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildDaySummary(totalHoy, totalTransacciones, promedio),
            const SizedBox(height: 20),
            ventasHoy.isNotEmpty
                ? _buildSalesList(ventasHoy)
                : _buildNoSalesMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Detalle de Ventas por Día',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildDateSelector() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.calendar_today),
      label: Text(formatter.format(fechaSeleccionada)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        final nuevaFecha = await showDatePicker(
          context: context,
          initialDate: fechaSeleccionada,
          firstDate: DateTime(2023, 1, 1),
          lastDate: DateTime(2023, 12, 31),
        );
        if (nuevaFecha != null) {
          setState(() => fechaSeleccionada = nuevaFecha);
        }
      },
    );
  }

  Widget _buildDaySummary(double total, int transacciones, double promedio) {
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
          _buildSummaryItem('Total', '\$${total.toStringAsFixed(2)}', Colors.blue),
          _buildSummaryItem('Transacciones', '$transacciones', Colors.green),
          _buildSummaryItem('Promedio', '\$${promedio.toStringAsFixed(2)}', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.attach_money, color: color),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSalesList(List<Map<String, dynamic>> ventas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ventas.map((venta) {
        return _buildSaleItem(
          venta['hora'],
          venta['ruta'],
          venta['monto'],
        );
      }).toList(),
    );
  }

  Widget _buildSaleItem(String hora, String ruta, double monto) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.directions_bus, color: Colors.orange),
        title: Text(ruta, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(hora),
        trailing: Text('\$${monto.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  Widget _buildNoSalesMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.info_outline, size: 48, color: Colors.orange),
          SizedBox(height: 12),
          Text(
            'No hay ventas registradas para esta fecha.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
