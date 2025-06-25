import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:logger/logger.dart';
import '../widgets/app_scaffold.dart';

class GestionPasajerosPage extends StatefulWidget {
  const GestionPasajerosPage({super.key});

  @override
  State<GestionPasajerosPage> createState() => _GestionPasajerosPageState();
}

class _GestionPasajerosPageState extends State<GestionPasajerosPage> {
  late mongo.Db _db;
  late mongo.DbCollection _collection;
  List<Map<String, dynamic>> pasajeros = [];

  final _logger = Logger();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();

  String _busqueda = '';
  int? _editIndex;
  double _rating = 4;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    try {
      _logger.i('Intentando conectar a MongoDB...');
_db = mongo.Db(
  'mongodb://azuleimymartin:zuly052639@ac-sacozvs-shard-00-00.s0b47ze.mongodb.net:27017,ac-sacozvs-shard-00-01.s0b47ze.mongodb.net:27017,ac-sacozvs-shard-00-02.s0b47ze.mongodb.net:27017/rutvans?ssl=true&replicaSet=atlas-sacozvs-shard-0&authSource=admin&retryWrites=true&w=majority',
);
await _db.open();
      _logger.i('Conexión a MongoDB abierta.');

      _collection = _db.collection('gestion_pasajeros');
      _logger.i('Colección gestion_pasajeros obtenida.');

      await _cargarPasajerosDesdeDB();
      _logger.i('Pasajeros cargados: $pasajeros');
    } catch (e) {
      _logger.e('Error conectando a MongoDB: $e');
    }
  }

  Future<void> _cargarPasajerosDesdeDB() async {
    try {
      _logger.i('Consultando pasajeros...');
      final data = await _collection.find().toList();
      _logger.i('Datos recibidos de la BD: ${data.length} documentos');

      setState(() {
        pasajeros = data.map<Map<String, dynamic>>((doc) {
          _logger.i('Procesando doc: $doc');
          return {
            'nombre': doc['nombre'] ?? '',
            'destino': doc['destino'] ?? '',
            'precio': (doc['precio'] ?? 0).toDouble(),
            'foto': doc['foto'] ?? '',
            'favorito': doc['favorito'] ?? false,
            '_id': doc['_id'],
          };
        }).toList();
      });
    } catch (e) {
      _logger.e('Error cargando pasajeros: $e');
    }
  }

  Future<void> _agregarPasajero(Map<String, dynamic> pasajero) async {
    try {
      await _collection.insertOne(pasajero);
      await _cargarPasajerosDesdeDB();
    } catch (e) {
      _logger.e('Error agregando pasajero: $e');
    }
  }

  Future<void> _editarPasajero(Map<String, dynamic> pasajero) async {
    try {
      var id = pasajero['_id'];
      if (id == null) return;
      await _collection.updateOne(
        mongo.where.id(id),
        mongo.modify
          ..set('nombre', pasajero['nombre'])
          ..set('destino', pasajero['destino'])
          ..set('precio', pasajero['precio'])
          ..set('foto', pasajero['foto'])
          ..set('favorito', pasajero['favorito']),
      );
      await _cargarPasajerosDesdeDB();
    } catch (e) {
      _logger.e('Error editando pasajero: $e');
    }
  }

  Future<void> _eliminarPasajero(mongo.ObjectId id) async {
    try {
      await _collection.deleteOne(mongo.where.id(id));
      await _cargarPasajerosDesdeDB();
    } catch (e) {
      _logger.e('Error eliminando pasajero: $e');
    }
  }

  void _showFormDialog({bool isEdit = false}) {
    if (isEdit && _editIndex != null) {
      final p = pasajeros[_editIndex!];
      _nombreController.text = p['nombre'];
      _destinoController.text = p['destino'];
      _precioController.text = p['precio'].toString();
      _fotoController.text = p['foto'];
    } else {
      _clearFields();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Editar Pasajero' : 'Agregar Pasajero',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_nombreController, 'Nombre'),
              const SizedBox(height: 8),
              _buildTextField(_destinoController, 'Destino'),
              const SizedBox(height: 8),
              _buildTextField(_precioController, 'Precio', isNumber: true),
              const SizedBox(height: 8),
              _buildTextField(_fotoController, 'Ruta de la Foto'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _seleccionarImagenGaleria,
                    icon: const Icon(Icons.photo),
                    label: const Text("Galería"),
                  ),
                  if (!kIsWeb)
                    TextButton.icon(
                      onPressed: _tomarFotoCamara,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Cámara"),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFields();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              final nombre = _nombreController.text.trim();
              final destino = _destinoController.text.trim();
              final precio = double.tryParse(_precioController.text.trim()) ?? 0.0;
              final foto = _fotoController.text.trim();

              if (nombre.isEmpty || destino.isEmpty || foto.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor completa todos los campos')),
                );
                return;
              }

              if (isEdit && _editIndex != null) {
                pasajeros[_editIndex!] = {
                  'nombre': nombre,
                  'destino': destino,
                  'precio': precio,
                  'foto': foto,
                  'favorito': pasajeros[_editIndex!]['favorito'],
                  '_id': pasajeros[_editIndex!]['_id'],
                };
                await _editarPasajero(pasajeros[_editIndex!]);
              } else {
                final nuevoPasajero = {
                  'nombre': nombre,
                  'destino': destino,
                  'precio': precio,
                  'foto': foto,
                  'favorito': false,
                };
                await _agregarPasajero(nuevoPasajero);
              }

              _clearFields();
              _editIndex = null;
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Guardar' : 'Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarImagenGaleria() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _fotoController.text = pickedFile.path;
      setState(() {});
    }
  }

  Future<void> _tomarFotoCamara() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _fotoController.text = pickedFile.path;
      setState(() {});
    }
  }

  void _compartirPasajero(int index) {
    final pasajero = pasajeros[index];
    Share.share(
        'Pasajero: ${pasajero['nombre']}\nDestino: ${pasajero['destino']}\nPrecio: \$${pasajero['precio']}');
  }

  void _llamarPasajero(String telefono) async {
    final uri = Uri.parse('tel:$telefono');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _clearFields() {
    _nombreController.clear();
    _destinoController.clear();
    _precioController.clear();
    _fotoController.clear();
  }

  TextField _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _editPasajero(int index) {
    _editIndex = index;
    _showFormDialog(isEdit: true);
  }

  void _deletePasajero(int index) async {
    final id = pasajeros[index]['_id'];
    if (id != null && id is mongo.ObjectId) {
      await _eliminarPasajero(id);
    }
  }

  void _showPasajeroDetalle(int index) {
    final pasajero = pasajeros[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(pasajero['nombre'],
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(pasajero['foto']),
            const SizedBox(height: 16),
            Text('Destino: ${pasajero['destino']}'),
            Text('Precio: \$${pasajero['precio'].toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            _ratingWidget(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _llamarPasajero('9993260577'),
            child: const Text('Llamar'),
          ),
          TextButton(
            onPressed: () => _compartirPasajero(index),
            child: const Text('Compartir'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _ratingWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return IconButton(
          icon: Icon(
            i < _rating ? Icons.star : Icons.star_border,
            color: Colors.orange,
          ),
          onPressed: () {
            setState(() {
              _rating = i + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildImage(String ruta) {
    if (kIsWeb) {
      if (ruta.startsWith('blob:') || ruta.startsWith('http')) {
        return Image.network(
          ruta,
          height: 150,
          width: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
        );
      } else {
        return Image.asset(
          ruta,
          height: 150,
          width: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50),
        );
      }
    } else {
      if (ruta.startsWith('/') || ruta.contains('\\')) {
        return Image.file(
          File(ruta),
          height: 150,
          width: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
        );
      } else {
        return Image.asset(
          ruta,
          height: 150,
          width: 150,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50),
        );
      }
    }
  }

@override
Widget build(BuildContext context) {
  final filtrados = pasajeros.where((p) {
    final nombreLower = p['nombre'].toString().toLowerCase();
    final destinoLower = p['destino'].toString().toLowerCase();
    return nombreLower.contains(_busqueda) || destinoLower.contains(_busqueda);
  }).toList();

  return AppScaffold(
    currentIndex: 0,
    currentDrawerIndex: 5,
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.orange,
      onPressed: () => _showFormDialog(),
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron pasajeros.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final pasajero = filtrados[index];
                    return GestureDetector(
                      onTap: () => _showPasajeroDetalle(pasajeros.indexOf(pasajero)),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: _buildImage(pasajero['foto']),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pasajero['nombre'],
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('Destino: ${pasajero['destino']}'),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text('\$${pasajero['precio'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        pasajero['favorito']
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: pasajero['favorito'] ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        pasajero['favorito'] = !pasajero['favorito'];
                                        await _editarPasajero(pasajero);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () =>
                                          _editPasajero(pasajeros.indexOf(pasajero)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () =>
                                          _deletePasajero(pasajeros.indexOf(pasajero)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar pasajero...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _busqueda = value.toLowerCase();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    if (_db.isConnected) {
      _db.close();
    }
    _nombreController.dispose();
    _destinoController.dispose();
    _precioController.dispose();
    _fotoController.dispose();
    super.dispose();
  }
}