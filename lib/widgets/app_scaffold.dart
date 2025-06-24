import 'package:flutter/material.dart';
import '../pages/ListaConductoresPage.dart';
import '../pages/NotificacionesPage.dart';
import '../pages/finanzas.dart';
import '../pages/home_page.dart';
import '../pages/LocalidadesPage.dart';
import '../pages/gestion_pasageros_page.dart';
import '../pages/Gestion_Incidencias_Page.dart';
import '../pages/Veiculos.dart';
import '../pages/Horarios.dart';
import '../pages/Usuarios.dart';
import '../pages/Rutas.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final int currentDrawerIndex;
  final Widget? floatingActionButton;  // <-- Agregar este campo

  const AppScaffold({
    super.key,
    required this.body,
    this.currentIndex = 0,
    this.currentDrawerIndex = -1,
    this.floatingActionButton,   // <-- Agregar parámetro
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: body,
      floatingActionButton: floatingActionButton,  // <-- Usar aquí
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Image.asset('images/logo.png', height: 40),
          const SizedBox(width: 10),
          const Text('RutVans', style: TextStyle(color: Colors.white)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesPage()),
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 10, minHeight: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsuarioPage()),
              );
            },
            child: const Icon(Icons.account_circle, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.orange,
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.account_circle, color: Colors.orange, size: 50),
            ),
            accountName: const Text('Administrador', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('admin@rutvans.com'),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home_outlined,
                  label: 'Inicio',
                  index: 0,
                  page: const HomePage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.directions_bus_filled_outlined,
                  label: 'Finanzas',
                  index: 1,
                  page: const FinanzasPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.directions_bus_filled_outlined,
                  label: 'Conductores',
                  index: 2,
                  page: const ListaConductoresPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.map_outlined,
                  label: 'Localidades',
                  index: 3,
                  page: const LocalitiesPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.map_outlined,
                  label: 'Rutas',
                  index: 4,
                  page: const RutasPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people_outline,
                  label: 'Gestión de Pasajeros',
                  index: 5,
                  page: const GestionPasajerosPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.directions_car_filled_outlined,
                  label: 'Gestión de Vehículos',
                  index: 6,
                  page: const ListaConductoresPages(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.report_problem_outlined,
                  label: 'Gestión de Incidencias',
                  index: 7,
                  page: const GestionIncidenciasPage(),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.schedule_outlined,
                  label: 'Horarios',
                  index: 8,
                  page: const HorariosPage(),
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout,
                  label: 'Cerrar sesión',
                  index: 9,
                  onTap: () {
                    Navigator.pop(context);
                    // lógica de logout
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    Widget? page,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey[800];

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label),
      selected: index == currentDrawerIndex,
      selectedTileColor: Colors.orange.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        } else if (page != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        }
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFFF6000),
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        Widget page;
        switch (index) {
          case 0:
            page = const HomePage();
            break;
          case 1:
            page = const FinanzasPage();
            break;
          case 2:
            page = const ListaConductoresPage();
            break;
          default:
            return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Finanzas'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Conductores'),
      ],
    );
  }
}
