import 'package:flutter/material.dart';
import '../widgets/App_Scaffold.dart';

class ListaConductoresPages extends StatefulWidget {
  const ListaConductoresPages({super.key});

  @override
  State<ListaConductoresPages> createState() => _ListaConductoresPageState();
}

class _ListaConductoresPageState extends State<ListaConductoresPages> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: 0, // índice del BottomNavigationBar si quieres controlarlo aquí
      currentDrawerIndex: 6, 
      body: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text(
            'Gestión de Flota',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Conductores'),
              Tab(text: 'Vehículos'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                'images/logo.png',
                height: 30,
              ),
            )
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildConductoresTab(),
            _buildVehiculosTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add),
          onPressed: () {
            if (_tabController.index == 0) {
              // Navegar a agregar conductor
            } else {
              // Navegar a agregar vehículo
            }
          },
        ),

      ),
    );
  }

  Widget _buildConductoresTab() {
    final List<Map<String, String>> conductores = [
      {
        'nombre': 'Juan Perez',
        'edad': '33',
        'experiencia': 'Buena',
        'telefono': '9993260577',
        'foto': 'images/conductor1.jpg',
      },
      {
        'nombre': 'Ernesto Martín',
        'edad': '35',
        'experiencia': 'Buena',
        'telefono': '9993260577',
        'foto': 'images/conductor2.jpg',
      },
      // ... resto de conductores
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        itemCount: conductores.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final conductor = conductores[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        conductor['foto']!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    conductor['nombre']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edad: ${conductor['edad']} años',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Experiencia: ${conductor['experiencia']}',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Tel: ${conductor['telefono']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehiculosTab() {
    final List<Map<String, String>> vehiculos = [
      {
        'modelo': 'Toyota Hiace',
        'año': '2022',
        'placa': 'ABC-1234',
        'capacidad': '15 pasajeros',
        'foto': 'images/vehiculo1.jpg',
      },
      {
        'modelo': 'Mercedes Sprinter',
        'año': '2021',
        'placa': 'DEF-5678',
        'capacidad': '12 pasajeros',
        'foto': 'images/vehiculo2.jpg',
      },
      // ... más vehículos
    ];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        itemCount: vehiculos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final vehiculo = vehiculos[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        vehiculo['foto']!,
                        width: 120,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vehiculo['modelo']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Año: ${vehiculo['año']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Placa: ${vehiculo['placa']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    vehiculo['capacidad']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
