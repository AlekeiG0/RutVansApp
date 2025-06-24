import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/App_Scaffold.dart';

class SalesReportPage extends StatelessWidget {
  const SalesReportPage({super.key});

  // Simulación de datos
  final List<double> ventasPorDia = const [450, 620, 300, 750, 480, 890, 920];
  final List<String> dias = const ['1', '5', '10', '15', '20', '25', '30'];

  final List<Map<String, dynamic>> rutas = const [
    {'nombre': 'Lima - Arequipa', 'monto': '\$2,450 (28%)', 'porcentaje': 0.28},
    {'nombre': 'Lima - Trujillo', 'monto': '\$1,890 (22%)', 'porcentaje': 0.22},
    {'nombre': 'Lima - Chiclayo', 'monto': '\$1,560 (18%)', 'porcentaje': 0.18},
    {'nombre': 'Lima - Piura', 'monto': '\$1,200 (14%)', 'porcentaje': 0.14},
    {'nombre': 'Otros', 'monto': '\$1,460 (18%)', 'porcentaje': 0.18},
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSection(),
            const SizedBox(height: 20),
            _buildDateSelector(),
            const SizedBox(height: 20),
            _buildSalesSummary(),
            const SizedBox(height: 20),
            _buildDetailedChart(),
            const SizedBox(height: 20),
            _buildTopRoutesList(),
            const SizedBox(height: 30),
            _buildExportButton(context),
          ],
        ),
      ),
    );
  }

  // ------------------------- WIDGETS -------------------------

  Widget _buildTitleSection() {
    return const Text(
      'Reporte de Ventas',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDateRangeButton(
            label: 'Fecha Inicio',
            date: '01/05/2023',
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDateRangeButton(
            label: 'Fecha Fin',
            date: '31/05/2023',
            icon: Icons.calendar_today,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeButton({
    required String label,
    required String date,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesSummary() {
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
          const Text('Resumen de Ventas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Ventas', '\$8,560', Colors.blue),
              _buildSummaryItem('Ventas Diarias', '\$285', Colors.green),
              _buildSummaryItem('Transacciones', '30', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.attach_money, color: color),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailedChart() {
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
          const Text('Ventas por Día',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < dias.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(dias[index]),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text('\$${value.toInt()}');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 1000,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      ventasPorDia.length,
                      (i) => FlSpot(i.toDouble(), ventasPorDia[i]),
                    ),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.1)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRoutesList() {
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
          const Text('Rutas Más Vendidas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...rutas.map((ruta) => _buildTopRouteItem(
            ruta['nombre'],
            ruta['monto'],
            ruta['porcentaje'],
          )),
        ],
      ),
    );
  }

  Widget _buildTopRouteItem(String route, String amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(route, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(amount, style: const TextStyle(color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            color: Colors.orange,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: const Text('Exportar a PDF',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _generateAndPrintPdf(context),
      ),
    );
  }

  Future<void> _generateAndPrintPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Reporte de Ventas - Mayo 2023',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Fecha Inicio: 01/05/2023'),
                pw.Text('Fecha Fin: 31/05/2023'),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text('Resumen de Ventas',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfSummaryItem('Total Ventas', '\$8,560'),
                _buildPdfSummaryItem('Ventas Diarias', '\$285'),
                _buildPdfSummaryItem('Transacciones', '30'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Rutas Más Vendidas',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              data: const [
                ['Ruta', 'Monto', 'Porcentaje'],
                ['Lima - Arequipa', '\$2,450', '28%'],
                ['Lima - Trujillo', '\$1,890', '22%'],
                ['Lima - Chiclayo', '\$1,560', '18%'],
                ['Lima - Piura', '\$1,200', '14%'],
                ['Otros', '\$1,460', '18%'],
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporte PDF generado con éxito'),
        backgroundColor: Colors.green,
      ),
    );
  }

  pw.Widget _buildPdfSummaryItem(String title, String value) {
    return pw.Column(
      children: [
        pw.Container(
          width: 60,
          height: 60,
          decoration: const pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: PdfColors.orange100,
          ),
          child: pw.Center(
            child: pw.Text(value,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }
}
