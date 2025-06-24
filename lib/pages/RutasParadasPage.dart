import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../dbHelper/mongodb.dart';
import '../widgets/App_Scaffold.dart';

class LocalitiesPage extends StatefulWidget {
  const LocalitiesPage({Key? key}) : super(key: key);

  @override
  State<LocalitiesPage> createState() => _LocalitiesPageState();
}

class _LocalitiesPageState extends State<LocalitiesPage> {
  List<Map<String, dynamic>> _localities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocalities();
  }

  Future<void> _fetchLocalities() async {
    try {
      await MongoDatabase.connect();
      final data = await MongoDatabase.getAllLocalities();
      setState(() {
        _localities = data;
        _loading = false;
      });
    } catch (e) {
      print('Error cargando localidades: $e');
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> reverseGeocode(LatLng pos) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${pos.latitude}&lon=${pos.longitude}&addressdetails=1',
    );

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'MiAppFlutterLocalities/1.0'
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error en geocoding inverso: $e');
    }
    return null;
  }

  Future<void> _showAddLocalityDialog(LatLng position) async {
    final _formKey = GlobalKey<FormState>();

    String latitude = position.latitude.toString();
    String longitude = position.longitude.toString();
    String locality = '';
    String municipality = '';
    String street = '';
    String postalCode = '';
    String state = '';
    String country = '';
    String localityType = '';

    final address = await reverseGeocode(position);
    if (address != null) {
      locality = address['neighbourhood'] ??
          address['suburb'] ??
          address['city_district'] ??
          address['city'] ??
          '';
      municipality = address['county'] ?? '';
      street = address['road'] ?? '';
      postalCode = address['postcode'] ?? '';
      state = address['state'] ?? '';
      country = address['country'] ?? '';
      localityType = address['type'] ?? '';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Agregar nueva localidad',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildReadOnlyField('Latitud', latitude),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Longitud', longitude),
                  const SizedBox(height: 8),
                  _buildEditableField(
                    label: 'Localidad',
                    initialValue: locality,
                    validatorMsg: 'La localidad es requerida',
                    onChanged: (v) => locality = v,
                  ),
                  const SizedBox(height: 8),
                  _buildEditableField(
                    label: 'Municipio',
                    initialValue: municipality,
                    validatorMsg: 'El municipio es requerido',
                    onChanged: (v) => municipality = v,
                  ),
                  const SizedBox(height: 8),
                  _buildEditableField(
                    label: 'Calle',
                    initialValue: street,
                    onChanged: (v) => street = v,
                  ),
                  const SizedBox(height: 8),
                  _buildEditableField(
                    label: 'Código Postal',
                    initialValue: postalCode,
                    onChanged: (v) => postalCode = v,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Estado', state),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('País', country),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Tipo de localidad', localityType),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final nowStr = DateTime.now()
                        .toIso8601String()
                        .substring(0, 19)
                        .replaceAll('T', ' ');

                    final newId = (_localities.isNotEmpty)
                        ? (_localities
                                .map((e) => e['id'] as int)
                                .reduce((a, b) => a > b ? a : b) +
                            1)
                        : 1;

                    await MongoDatabase.addLocality({
                      'id': newId,
                      'longitude': longitude,
                      'latitude': latitude,
                      'locality': locality,
                      'street': street,
                      'postal_code': postalCode,
                      'municipality': municipality,
                      'state': state,
                      'country': country,
                      'locality_type': localityType,
                      'created_at': nowStr,
                      'updated_at': nowStr,
                    });

                    Navigator.of(context).pop();
                    _fetchLocalities();
                  } catch (e) {
                    print('Error guardando localidad: $e');
                  }
                }
              },
              child: const Text('Guardar', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      readOnly: true,
    );
  }

  Widget _buildEditableField({
    required String label,
    required String initialValue,
    String? validatorMsg,
    required void Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validatorMsg != null
          ? (v) => v == null || v.isEmpty ? validatorMsg : null
          : null,
      onChanged: onChanged,
      keyboardType: keyboardType,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: AppScaffold(
          currentIndex: 0,
         
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: AppScaffold(
        currentIndex: 0, 
        currentDrawerIndex: 3, 
        body: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Localidades'),
              bottom: const TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.list), text: 'Lista'),
                  Tab(icon: Icon(Icons.map), text: 'Mapa'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildListView(),
                _buildMapView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_localities.isEmpty) {
      return const Center(
        child: Text(
          'No hay localidades disponibles',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _localities.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final loc = _localities[index];
        return Dismissible(
          key: ValueKey(loc['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content: Text(
                        '¿Deseas eliminar la localidad "${loc['locality']}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (direction) async {
            try {
              await MongoDatabase.deleteLocality(loc['id'] as int);
              setState(() {
                _localities.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Localidad eliminada')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al eliminar: $e')),
              );
            }
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.location_city, color: Colors.white),
            ),
            title: Text(
              '${loc['locality']}, ${loc['municipality']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${loc['street']}, CP ${loc['postal_code']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final center = _localities.isNotEmpty
        ? LatLng(
            double.tryParse(_localities[0]['latitude']) ?? 20.967370,
            double.tryParse(_localities[0]['longitude']) ?? -89.617020,
          )
        : const LatLng(20.967370, -89.617020);

    final markers = _localities.map((loc) {
      final lat = double.tryParse(loc['latitude'] ?? '');
      final lng = double.tryParse(loc['longitude'] ?? '');
      if (lat == null || lng == null) return null;

      return Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 50,
        child: Tooltip(
          message: '${loc['locality']}, ${loc['municipality']}',
          child: const Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 40,
            shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
          ),
        ),
      );
    }).whereType<Marker>().toList();

    return FlutterMap(
      options: MapOptions(
        center: center,
        zoom: 13,
        onTap: (tapPosition, point) => _showAddLocalityDialog(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tuapp.flutterlocalities',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
