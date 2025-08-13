import 'package:flutter/material.dart';
import '../../services/site_service.dart';
import '../../widgets/app_scaffold.dart';

class ListaSitesPage extends StatefulWidget {
  const ListaSitesPage({Key? key}) : super(key: key);

  @override
  State<ListaSitesPage> createState() => _ListaSitesPageState();
}

class _ListaSitesPageState extends State<ListaSitesPage> {
  late Future<List<dynamic>> _sites;

  final Color primaryColor = const Color(0xFFE65100); // naranja oscuro
  final Color textColor = const Color(0xFF4E342E); // marrón oscuro
  final Color cardBackground = const Color(0xFFFFF3E0); // naranja muy suave
  final Color iconColor = const Color(0xFFE65100); // naranja oscuro

  @override
  void initState() {
    super.initState();
    _sites = SiteService.getSites();
  }
@override
Widget build(BuildContext context) {
  return AppScaffold(
    appBarTitle: 'Lista de Sitios',
    currentIndex: -1,
    currentDrawerIndex: 7,
    body: FutureBuilder<List<dynamic>>(
      future: _sites,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          );
        }
        final sites = snapshot.data ?? [];
        if (sites.isEmpty) {
          return Center(
            child: Text(
              'No hay sitios disponibles',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: sites.length,
          itemBuilder: (context, index) {
            final site = sites[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shadowColor: primaryColor.withOpacity(0.2),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.location_on, color: primaryColor, size: 28),
                ),
                title: Text(
                  site['name'] ?? 'Sin nombre',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  site['locality']?['locality'] ?? 'Sin localidad',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: primaryColor.withOpacity(0.7),
                  size: 20,
                ),
                onTap: () {
                  // Aquí puedes agregar navegación o acciones al tocar el sitio
                },
              ),
            );
          },
        );
      },
    ),
  );
}

}
