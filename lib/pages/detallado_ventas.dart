import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class DetalladoVentasPage extends StatefulWidget {
  const DetalladoVentasPage({Key? key}) : super(key: key);

  @override
  State<DetalladoVentasPage> createState() => _DetalladoVentasPageState();
}

class _DetalladoVentasPageState extends State<DetalladoVentasPage> {
  DateTime fechaSeleccionada = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormatter = DateFormat('dd/MM/yyyy');

  List<Map<String, dynamic>> ventas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => cargando = true);
    try {
      final data = await ApiService.getVentasPorFecha(
        fecha: formatter.format(fechaSeleccionada),
      );
      setState(() {
        ventas = List<Map<String, dynamic>>.from(data['ventas'] ?? []);
      });
    } catch (e) {
      print('Error al cargar ventas: $e');
    } finally {
      setState(() => cargando = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (nuevaFecha != null) {
      setState(() => fechaSeleccionada = nuevaFecha);
      _cargarVentas();
    }
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Reporte Detallado - ${displayFormatter.format(fechaSeleccionada)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...ventas.map((v) => pw.Text(
              'Folio: ${v['folio']} - \$${v['amount']} - Fecha: ${v['created_at']}',
            )),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> _exportarExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Ventas'];

    sheet.appendRow(['Folio', 'Monto', 'Fecha']);

    for (var v in ventas) {
      sheet.appendRow([v['folio'], v['amount'], v['created_at']]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'ventas_${formatter.format(fechaSeleccionada)}.xlsx',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ventas.fold(0.0, (sum, v) => sum + (v['amount'] ?? 0.0));
    final promedio = ventas.isNotEmpty ? total / ventas.length : 0.0;

    return AppScaffold(
      currentIndex: 0,
      body: Padding(
        
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalle de Ventas por Día',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(displayFormatter.format(fechaSeleccionada)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  tooltip: 'Exportar PDF',
                  onPressed: ventas.isEmpty ? null : _exportarPDF,
                ),
                IconButton(
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  tooltip: 'Exportar Excel',
                  onPressed: ventas.isEmpty ? null : _exportarExcel,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildResumen(total, ventas.length, promedio),
            const SizedBox(height: 20),
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ventas.isEmpty
                      ? _buildNoSalesMessage()
                      : ListView.builder(
                          itemCount: ventas.length,
                          itemBuilder: (_, i) => _buildVentaItem(ventas[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen(double total, int transacciones, double promedio) {
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
          _buildResumenItem('Total', '\$${total.toStringAsFixed(2)}', Colors.blue),
          _buildResumenItem('Transacciones', '$transacciones', Colors.green),
          _buildResumenItem('Promedio', '\$${promedio.toStringAsFixed(2)}', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, Color color) {
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

  Widget _buildVentaItem(Map<String, dynamic> venta) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.orange),
        title: Text('Folio: ${venta['folio'] ?? '—'}'),
        subtitle: Text('Fecha: ${venta['created_at'] ?? '—'}'),
        trailing: Text(
          '\$${(venta['amount'] ?? 0.0).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
