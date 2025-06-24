import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'DetalleConductorPage.dart';
import '../widgets/App_Scaffold.dart';

class ListaConductoresPage extends StatelessWidget {
  const ListaConductoresPage({super.key});

  Future<void> _llamarConductor(String telefono) async {
    final Uri url = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'No se pudo realizar la llamada al número $telefono';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> conductores = [
      {
        'nombre': 'Juan Perez',
        'edad': '33',
        'experiencia': 'Buena',
        'telefono': '9971560587',
        'foto': 'images/conductor1.jpg',
      },
      {
        'nombre': 'Ernesto Martín',
        'edad': '35',
        'experiencia': 'Buena',
        'telefono': '9993260577',
        'foto': 'images/conductor2.jpg',
      },
      {
        'nombre': 'Jorge López',
        'edad': '44',
        'experiencia': 'Alta',
        'telefono': '9993260577',
        'foto': 'images/conductor3.jpg',
      },
      {
        'nombre': 'Carlos Ruiz',
        'edad': '30',
        'experiencia': 'Media',
        'telefono': '9993260577',
        'foto': 'images/conductor4.jpg',
      },
      {
        'nombre': 'Luis Sánchez',
        'edad': '37',
        'experiencia': 'Alta',
        'telefono': '9993260577',
        'foto': 'images/conductor5.jpg',
      },
      {
        'nombre': 'Pedro García',
        'edad': '40',
        'experiencia': 'Buena',
        'telefono': '9993260577',
        'foto': 'images/conductor6.jpg',
      },
    ];

    return AppScaffold(
        currentIndex: 0,
        currentDrawerIndex: 2, 
      body: Padding(
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
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetalleConductorPage(conductor: conductor),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      Text('Edad: ${conductor['edad']} años'),
                      Text('Experiencia: ${conductor['experiencia']}'),
                      Text('Tel: ${conductor['telefono']}'),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _llamarConductor(conductor['telefono']!),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Llamar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    
    );
  }
}
