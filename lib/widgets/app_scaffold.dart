import 'package:flutter/material.dart';
import 'package:mobil_rutvans/pages/Horarios/horarios.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login.dart';
import '../pages/Cajeros/cashier_page.dart';
import '../pages/Conductores/ListaConductoresPage.dart';
import '../pages/Coordinadores/coordinator_Page.dart';
import '../pages/Finanzas/finanzas.dart';
import '../pages/Locations/LocalidadesPage.dart';
import '../pages/Locations/Rutas.dart';
import '../pages/Locations/lista_sites_page.dart';
import '../pages/NotificacionesPage.dart';
import '../pages/UsuarioPage.dart';
import '../pages/home_page.dart';
import '../pages/Horarios/horarios.dart';
import '../pages/unidades_page.dart';
import '../services/auth_service.dart';
import '../services/usuario_service.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  /// Índice del BottomNavigationBar: 0..2 o -1 si no hay ninguna pestaña activa
  final int currentIndex;
  final int currentDrawerIndex;
  final Widget? floatingActionButton;
  final String? email;
  final String? appBarTitle;

  const AppScaffold({
    super.key,
    required this.body,
    this.email,
    this.currentIndex = 0,
    this.currentDrawerIndex = -1,
    this.floatingActionButton,
    this.appBarTitle,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  String nombreUsuario = 'Administrador';
  String emailUsuario = 'admin@rutvans.com';
  String fotoUsuario = '';

  final Color primaryColor = const Color(0xFFE65100); // naranja oscuro
  final Color accentColor = const Color(0xFFFF6D00); // naranja vivo
  final Color backgroundColor = const Color.fromARGB(255, 255, 255, 255); // crema claro
  final Color drawerBackground = Colors.white;
  final Color drawerSelected = const Color(0xFFFFF3E0); // naranja muy suave
  final Color drawerTextColor = const Color(0xFF4E342E); // marrón oscuro suave para texto
  final Color drawerIconColor = const Color(0xFFE65100); // naranja oscuro para iconos
  final Color dividerColor = Colors.grey.shade300;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final perfil = await UsuarioService.obtenerPerfil();

    if (perfil != null) {
      setState(() {
        nombreUsuario = perfil['name'] ?? '';
        emailUsuario = perfil['email'] ?? '';
        fotoUsuario = perfil['profile_photo_url'] ?? '';
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        nombreUsuario = prefs.getString('nombre_usuario') ?? '';
        emailUsuario = prefs.getString('email_usuario') ?? '';
        fotoUsuario = prefs.getString('foto_usuario') ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validamos índice para que sea -1 o entre 0 y 2 (items del BottomNavigationBar)
    final isIndexValid = widget.currentIndex >= 0 && widget.currentIndex < 3;
    // Índice que se pasa al BottomNavigationBar, si no es válido se pasa 0 (pero no se pinta seleccionado)
    final int bottomNavIndex = isIndexValid ? widget.currentIndex : 0;
    // Si currentIndex es -1 o inválido, forzamos estilos para que no parezca seleccionado.

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: bottomNavIndex,
        selectedItemColor: isIndexValid ? primaryColor : Colors.grey.shade600,
        unselectedItemColor: isIndexValid ? Colors.grey.shade600 : Colors.grey.shade600,
        selectedLabelStyle: TextStyle(
          fontWeight: isIndexValid ? FontWeight.w600 : FontWeight.w400,
          color: isIndexValid ? primaryColor : Colors.grey.shade600,
        ),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == widget.currentIndex) return;

          Widget page;
          switch (index) {
            case 0:
              page = const HomePage();
              break;
            case 1:
              page = const FinanzasPage();
              break;
            case 2:
              page = const DriversPage();
              break;
            case 3:
              page = const HorariosPage();
              break;
            default:
              return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: isIndexValid && bottomNavIndex == 0 ? primaryColor : Colors.grey.shade600,
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.attach_money,
              color: isIndexValid && bottomNavIndex == 1 ? primaryColor : Colors.grey.shade600,
            ),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group,
              color: isIndexValid && bottomNavIndex == 2 ? primaryColor : Colors.grey.shade600,
            ),
            label: 'Conductores',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.group,
              color: isIndexValid && bottomNavIndex == 3 ? primaryColor : Colors.grey.shade600,
            ),
            label: 'Horarios',
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final title = widget.appBarTitle ?? 'RutVans';

    return AppBar(
      backgroundColor: primaryColor,
      elevation: 4,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menú',
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 40),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificacionesPage()),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UsuarioPerfilPage()),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: fotoUsuario.isNotEmpty ? NetworkImage(fotoUsuario) : null,
              child: fotoUsuario.isEmpty
                  ? const Icon(Icons.account_circle, color: Colors.grey, size: 32)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: drawerBackground,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: fotoUsuario.isNotEmpty ? NetworkImage(fotoUsuario) : null,
              child: fotoUsuario.isEmpty
                  ? Icon(
                      Icons.account_circle,
                      color: primaryColor,
                      size: 56,
                    )
                  : null,
            ),
            accountName: Text(
              nombreUsuario,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
            ),
            accountEmail: Text(
              emailUsuario,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                _buildDrawerItem(context, Icons.home_outlined, 'Inicio', 0, const HomePage()),
                _buildDrawerItem(context, Icons.attach_money, 'Finanzas', 1, const FinanzasPage()),
                _buildDrawerItem(context, Icons.group, 'Conductores', 2, const DriversPage()),
                _buildDrawerItem(context, Icons.group, 'Horarios', 3, const HorariosPage()),
                _buildDrawerItem(context, Icons.people_outline, 'Coordinadores', 4, const CoordinatorsPage()),
                _buildDrawerItem(context, Icons.point_of_sale_outlined, 'Cajeros', 5, const CashiersPage()),
                _buildDrawerItem(context, Icons.location_city_outlined, 'Localidades', 6, const LocalitiesPage()),
                _buildDrawerItem(context, Icons.route_outlined, 'Rutas', 7, const RutasPage()),
                _buildDrawerItem(context, Icons.map_outlined, 'Sitios', 8, const ListaSitesPage()),
                _buildDrawerItem(context, Icons.directions_car_filled_outlined, 'Gestión de Vehículos', 9, const UnitsPage()),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: Icon(Icons.logout, color: drawerIconColor),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(color: drawerTextColor, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await _showLogoutDialog(context);
                    if (confirm != true) return;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    );

                    await AuthService.logout();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    Navigator.pop(context); // Cierra loader

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage(title: 'RutVans')),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String label, int index, Widget page) {
    final selected = index == widget.currentDrawerIndex;

    return Container(
      color: selected ? drawerSelected : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: selected ? primaryColor : drawerIconColor, size: 26),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 16,
            color: selected ? primaryColor : drawerTextColor,
          ),
        ),
        selected: selected,
        onTap: () {
          Navigator.pop(context);
          if (index != widget.currentDrawerIndex) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => page));
          }
        },
      ),
    );
  }
}
