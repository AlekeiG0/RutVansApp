import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  String viajesHoy = '24'; // Puedes cambiar después a real si tienes datos
  String conductores = '0';
  String ingresosTotales = '\$5,509'; // También podrías hacerlo dinámico

  @override
  void initState() {
    super.initState();
    cargarDatosResumen();
  }

  Future<void> cargarDatosResumen() async {
    try {
      // Obtener todas las rutas
      final rutas = await RouteService.getAllRoutes();
      // Obtener todos los conductores
      final drivers = await DriverService.getAllDrivers();

      print("Rutas obtenidas: ${rutas.length}");
      print("Conductores obtenidos: ${drivers.length}");

      setState(() {
        rutasActivas = rutas.length.toString();
        conductores = drivers.length.toString();
      });
    } catch (e) {
      print('Error cargando datos resumen: $e');
      // Mantener valores por defecto en UI
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        WeatherCard(
                          temperature: data['temp'],
                          description: data['description'],
                          iconCode: data['icon'],
                          city: data['city'],
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            ResumenCards(
              rutasActivas: rutasActivas,
              viajesHoy: viajesHoy,
              conductores: conductores,
              ingresosTotales: ingresosTotales,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo viaje"),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
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
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: 450,
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 100,
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
                                  if (value.toInt() < 0 || value.toInt() > 6)
                                    return const SizedBox.shrink();
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
                                interval: 100,
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
                              spots: const [
                                FlSpot(0, 100),
                                FlSpot(1, 150),
                                FlSpot(2, 200),
                                FlSpot(3, 300),
                                FlSpot(4, 250),
                                FlSpot(5, 400),
                                FlSpot(6, 350),
                              ],
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.lightBlueAccent],
                              ),
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 80),
                                FlSpot(1, 100),
                                FlSpot(2, 120),
                                FlSpot(3, 150),
                                FlSpot(4, 130),
                                FlSpot(5, 160),
                                FlSpot(6, 140),
                              ],
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.orange,
                                  Colors.deepOrangeAccent,
                                ],
                              ),
                              barWidth: 4,
                              dotData: FlDotData(show: true),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.black87,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '${spot.y.toInt()} viajes',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
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
}

// El resto de widgets como WeatherCard, exportarPDF, CustomCard, RecentTrip permanecen igual


// ------------------- Widgets personalizados -------------------


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
            // Icono
            Image.network(
              'https://openweathermap.org/img/wn/$iconCode@2x.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 8),

            // Ciudad al lado del icono
            if (city != null)
              Text(
                city!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(width: 12),

            // Temperatura y descripción en columna, pero sin mucho espacio vertical
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

Future<void> exportarPDF(BuildContext context) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Reporte de Viajes',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Viajes de hoy: 24'),
          pw.Text('Pasajeros este mes: 500'),
          pw.Text('Rutas activas: 10'),
          pw.Text('Ingresos totales: \$5,509'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Viajes recientes:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(text: 'Centro → Aeropuerto - \$40.00'),
          pw.Bullet(text: 'Parque Norte → Playa - \$32.50'),
          pw.Bullet(text: 'Estación Central → Avenida 5 - \$46.00'),
          pw.Bullet(text: 'Colonia Este → Centro - \$38.75'),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
