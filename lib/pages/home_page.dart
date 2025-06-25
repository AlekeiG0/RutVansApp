import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart' as pw; // Added PdfPageFormat and PdfColor
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/App_Scaffold.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/ResumenCards.dart';
import '../dbHelper/mongodb.dart';
import '../dbHelper/route_db.dart';
import '../dbHelper/driver_db.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String rutasActivas = '0';
  String ventasTotales = '0';
  String conductores = '0';
  String ingresosTotales = '\$0.00';

  // Datos dinámicos para la gráfica
  List<FlSpot> spotsBlue = [];
  List<FlSpot> spotsOrange = [];

  // Mapas para guardar datos para las etiquetas (ventas e ingresos por día)
  Map<int, int> ventasPorDia = {};
  Map<int, double> ingresosPorDia = {};

  @override
  void initState() {
    super.initState();
    cargarDatosResumen();
  }

  Future<void> cargarDatosResumen() async {
    try {
      final ventas = await VentasService.getAllventas();
      final rutas = await RouteService.getAllRoutes();
      final drivers = await DriverService.getAllDrivers();

      // Calcular total de ingresos
      double totalIngresos = ventas.fold(0.0, (suma, venta) {
        final amountField = venta['amount'];
        final amount = amountField is num
            ? amountField.toDouble()
            : double.tryParse(amountField.toString()) ?? 0.0;
        return suma + amount;
      });

      // Inicializar conteo por día
      ventasPorDia = {for (var i = 0; i < 7; i++) i: 0};
      ingresosPorDia = {for (var i = 0; i < 7; i++) i: 0.0};

      for (var venta in ventas) {
        if (venta['created_at'] != null) {
          DateTime fecha;
          try {
            fecha = DateTime.parse(venta['created_at'].toString());
          } catch (_) {
            continue;
          }
          int diaSemana = fecha.weekday - 1; // 0=Lun ... 6=Dom
          if (ventasPorDia.containsKey(diaSemana)) {
            ventasPorDia[diaSemana] = ventasPorDia[diaSemana]! + 1;
            final amountField = venta['amount'];
            final amount = amountField is num
                ? amountField.toDouble()
                : double.tryParse(amountField.toString()) ?? 0.0;
            ingresosPorDia[diaSemana] = ingresosPorDia[diaSemana]! + amount;
          }
        }
      }

      // Generar FlSpot para la línea azul (ventas diarias)
      List<FlSpot> line1 = [];
      for (int i = 0; i < 7; i++) {
        line1.add(FlSpot(i.toDouble(), ventasPorDia[i]?.toDouble() ?? 0));
      }

      // Línea naranja con datos simulados (puedes adaptar o remover)
      List<FlSpot> line2 = [
        FlSpot(0, 80),
        FlSpot(1, 100),
        FlSpot(2, 120),
        FlSpot(3, 150),
        FlSpot(4, 130),
        FlSpot(5, 160),
        FlSpot(6, 140),
      ];

      setState(() {
        ventasTotales = ventas.length.toString();
        ingresosTotales = '\$${totalIngresos.toStringAsFixed(2)}';
        rutasActivas = rutas.length.toString();
        conductores = drivers.length.toString();
        spotsBlue = line1;
        spotsOrange = line2;
      });
    } catch (e) {
      print('Error cargando datos resumen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: fetchWeather(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Error al cargar el clima.'),
                  );
                } else {
                  final data = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: WeatherCard(
                      temperature: data['temp'],
                      description: data['description'],
                      iconCode: data['icon'],
                      city: data['city'],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ResumenCards(
              rutasActivas: rutasActivas,
              ventasTotales: ventasTotales,
              conductores: conductores,
              ingresosTotales: ingresosTotales,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
  
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text("Exportar"),
                    onPressed: () => exportarPDF(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.deepOrangeAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CustomCard(
                    title: 'Estadísticas de Viajes',
                    content: SizedBox(
                      height: 220,
                      child: spotsBlue.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: 6,
                                minY: 0,
                                maxY: (spotsBlue
                                            .map((s) => s.y)
                                            .reduce((a, b) => a > b ? a : b) +
                                        10)
                                    .ceilToDouble(),
                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: 10,
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        const days = [
                                          'Lun',
                                          'Mar',
                                          'Mié',
                                          'Jue',
                                          'Vie',
                                          'Sáb',
                                          'Dom',
                                        ];
                                        if (value.toInt() < 0 ||
                                            value.toInt() > 6) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            days[value.toInt()],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 20,
                                      reservedSize: 42,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spotsBlue,
                                    isCurved: true,
                                    gradient: const LinearGradient(
                                      colors: [Colors.blue, Colors.lightBlueAccent],
                                    ),
                                    barWidth: 4,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) {
                                        return _DotWithLabelPainter(
                                          ventas: ventasPorDia[spot.x.toInt()] ?? 0,
                                          ingresos:
                                              ingresosPorDia[spot.x.toInt()] ?? 0.0,
                                        );
                                      },
                                    ),
                                  ),
                                 
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor: Colors.black87,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        if (spot.barIndex == 0) {
                                          final dia = spot.x.toInt();
                                          final ventasTooltip =
                                              ventasPorDia[dia] ?? 0;
                                          final ingresosTooltip =
                                              ingresosPorDia[dia] ?? 0.0;
                                          return LineTooltipItem(
                                            'Ventas: $ventasTooltip\nIngresos: \$${ingresosTooltip.toStringAsFixed(2)}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        } else {
                                          return LineTooltipItem(
                                            '${spot.y.toInt()}',
                                            const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const CustomCard(
                    title: 'Viajes Recientes',
                    content: Column(
                      children: [
                        RecentTrip(
                          origin: 'Centro',
                          destination: 'Aeropuerto',
                          price: '\$40.00',
                        ),
                        RecentTrip(
                          origin: 'Parque Norte',
                          destination: 'Playa',
                          price: '\$32.50',
                        ),
                        RecentTrip(
                          origin: 'Estación Central',
                          destination: 'Avenida 5',
                          price: '\$46.00',
                        ),
                        RecentTrip(
                          origin: 'Colonia Este',
                          destination: 'Centro',
                          price: '\$38.75',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const CustomCard(
                    title: 'Alertas del sistema',
                    content: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.warning, color: Colors.redAccent),
                          title: Text('Ruta 3 tiene retrasos por tráfico.'),
                        ),
                        ListTile(
                          leading: Icon(Icons.info, color: Colors.blueAccent),
                          title: Text('Nuevo conductor registrado.'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, Admin 👋',
            style: TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '¿Listo para gestionar rutas y mejorar la experiencia del pasajero?',
            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.3),
          ),
        ],
      ),
    );
  }

  Future<void> exportarPDF(BuildContext context) async {
    final pdf = pw.Document();

    // Definir estilos
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: pw.PdfColor.fromHex('#000000'),
    );
    final subtitleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: pw.PdfColor.fromHex('#333333'),
    );
    final textStyle = pw.TextStyle(
      fontSize: 14,
      color: pw.PdfColor.fromHex('#000000'),
    );

    // Obtener datos recientes de ventas para los viajes
    final ventas = await VentasService.getAllventas();
    List<pw.Widget> recentTrips = [];
    for (var venta in ventas.take(4)) {
      final origin = venta['origin']?.toString() ?? 'Desconocido';
      final destination = venta['destination']?.toString() ?? 'Desconocido';
      final amountField = venta['amount'];
      final amount = amountField is num
          ? amountField.toDouble()
          : double.tryParse(amountField.toString()) ?? 0.0;
      recentTrips.add(
        pw.Bullet(
          text: '$origin → $destination - \$${amount.toStringAsFixed(2)}',
          style: textStyle,
        ),
      );
    }

    // Crear tabla para estadísticas semanales
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    List<pw.TableRow> tableRows = [];
    for (int i = 0; i < 7; i++) {
      tableRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(days[i], style: textStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text((ventasPorDia[i] ?? 0).toString(), style: textStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('\$${(ingresosPorDia[i] ?? 0.0).toStringAsFixed(2)}', style: textStyle),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pw.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Text('Reporte de Viajes', style: titleStyle),
          pw.SizedBox(height: 20),
          pw.Text('Resumen General', style: subtitleStyle),
          pw.SizedBox(height: 10),
          pw.Text('Rutas Activas: $rutasActivas', style: textStyle),
          pw.Text('Ventas Totales: $ventasTotales', style: textStyle),
          pw.Text('Conductores: $conductores', style: textStyle),
          pw.Text('Ingresos Totales: $ingresosTotales', style: textStyle),
          pw.SizedBox(height: 20),
          pw.Text('Estadísticas Semanales', style: subtitleStyle),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Día', style: subtitleStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Ventas', style: subtitleStyle),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Ingresos', style: subtitleStyle),
                  ),
                ],
              ),
              ...tableRows,
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Viajes Recientes', style: subtitleStyle),
          pw.SizedBox(height: 10),
          ...recentTrips,
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}

class _DotWithLabelPainter extends FlDotPainter {
  final int ventas;
  final double ingresos;

  _DotWithLabelPainter({
    required this.ventas,
    required this.ingresos,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final paint = Paint()..color = Colors.blue;

    canvas.drawCircle(offsetInCanvas, 6, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$ventas\n\$${ingresos.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offsetTexto = Offset(
      offsetInCanvas.dx - textPainter.width / 2,
      offsetInCanvas.dy - 6 - textPainter.height - 4,
    );

    textPainter.paint(canvas, offsetTexto);
  }

  @override
  Size getSize(FlSpot spot) {
    return const Size(40, 40);
  }

  @override
  List<Object?> get props => [ventas, ingresos];
}

class VentasService {
  static Future<List<Map<String, dynamic>>> getAllventas() async {
    final result = await MongoDatabase.ventasCollection.find().toList();

    for (var venta in result) {
      if (venta['data'] is String) {
        try {
          venta['data'] = json.decode(venta['data']);
        } catch (e) {
          venta['data'] = {};
        }
      }
    }

    return result.cast<Map<String, dynamic>>();
  }
}

class WeatherCard extends StatelessWidget {
  final String temperature;
  final String description;
  final String iconCode;
  final String? city;

  const WeatherCard({
    Key? key,
    required this.temperature,
    required this.description,
    required this.iconCode,
    this.city,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              'https://openweathermap.org/img/wn/$iconCode@2x.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 8),
            if (city != null)
              Text(
                city!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$temperature °C', style: const TextStyle(fontSize: 16)),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final Widget content;

  const CustomCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}

class RecentTrip extends StatelessWidget {
  final String origin;
  final String destination;
  final String price;

  const RecentTrip({
    super.key,
    required this.origin,
    required this.destination,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.deepOrangeAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.directions_car, color: Colors.deepOrangeAccent),
      ),
      title: Text(
        '$origin → $destination',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Text(
        price,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> fetchWeather() async {
  const apiKey = '880ab54dc134b873d3dbcc4476950287';
  const city = 'Maxcanú';
  const units = 'metric';
  const lang = 'es';
  final url = Uri.parse(
    'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=$units&lang=$lang',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final double temp = data['main']['temp']?.toDouble() ?? 0.0;

    return {
      'city': data['name'],
      'temp': temp.toStringAsFixed(1),
      'description': data['weather'][0]['description'],
      'icon': data['weather'][0]['icon'],
    };
  } else {
    throw Exception('Error al obtener el clima: ${response.statusCode}');
  }
}