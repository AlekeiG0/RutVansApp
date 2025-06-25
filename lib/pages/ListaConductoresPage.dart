import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:url_launcher/url_launcher.dart';
import 'DetalleConductorPage.dart';
import '../widgets/app_scaffold.dart';
class ListaConductoresPage extends StatefulWidget {
  const ListaConductoresPage({super.key});

  @override
  State<ListaConductoresPage> createState() => _ListaConductoresPageState();
}

class _ListaConductoresPageState extends State<ListaConductoresPage> {
  late mongo.Db _db;
  late mongo.DbCollection _collection;

  List<Map<String, dynamic>> conductores = [];
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initDbAndLoadConductores();
  }

  Future<void> _initDbAndLoadConductores() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    try {
_db = mongo.Db(
  'mongodb://azuleimymartin:zuly052639@ac-sacozvs-shard-00-00.s0b47ze.mongodb.net:27017,ac-sacozvs-shard-00-01.s0b47ze.mongodb.net:27017,ac-sacozvs-shard-00-02.s0b47ze.mongodb.net:27017/rutvans?ssl=true&replicaSet=atlas-sacozvs-shard-0&authSource=admin&retryWrites=true&w=majority',
);
await _db.open();


      _collection = _db.collection('conductores');

      final data = await _collection.find().toList();

      setState(() {
        conductores = data.map((doc) {
          return {
            'nombre': doc['nombre'] ?? '',
            'edad': doc['edad']?.toString() ?? 'N/A',
            'experiencia': doc['experiencia'] ?? 'N/A',
            'telefono': doc['telefono'] ?? 'N/A',
            'foto': doc['foto'] ?? 'images/default_conductor.jpg',
            '_id': doc['_id'],
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _llamarConductor(String telefono) async {
    final Uri url = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo realizar la llamada al número $telefono')),
      );
    }
  }

  @override
  void dispose() {
    if (_db.isConnected) {
      _db.close();
    }
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  if (_loading) {
    return const AppScaffold(
      currentIndex: 2,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  if (_errorMessage.isNotEmpty) {
    return AppScaffold(
      currentIndex: 2,
      body: Center(
        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  return AppScaffold(
    currentIndex: 2,
    body: Padding(
      padding: const EdgeInsets.all(12.0),
      child: conductores.isEmpty
          ? const Center(child: Text('No hay conductores disponibles.'))
          : GridView.builder(
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
                        builder: (context) => DetalleConductorPage(conductor: conductor),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                 child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
  child: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 3),
          ),
          child: ClipOval(
            child: _buildImage(conductor['foto']),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          conductor['nombre'],
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
          onPressed: () => _llamarConductor(conductor['telefono']),
          icon: const Icon(Icons.call, size: 18),
          label: const Text('Llamar'),
        ),
      ],
    ),
  ),
),

                  ),
                );
              },
            ),
    ),
  );
}


  Widget _buildImage(String ruta) {
    if (kIsWeb) {
      if (ruta.startsWith('http') || ruta.startsWith('blob:')) {
        return Image.network(
          ruta,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
        );
      } else {
        return Image.asset(
          ruta,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80),
        );
      }
    } else {
      if (ruta.startsWith('/') || ruta.contains('\\')) {
        return Image.file(
          File(ruta),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
        );
      } else {
        return Image.asset(
          ruta,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80),
        );
      }
    }
  }
}