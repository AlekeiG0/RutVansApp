import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../widgets/App_Scaffold.dart';
import '../../services/locality_api_service.dart';

class LocalitiesPage extends StatefulWidget {
  const LocalitiesPage({Key? key}) : super(key: key);

  @override
  State<LocalitiesPage> createState() => _LocalitiesPageState();
}

class _LocalitiesPageState extends State<LocalitiesPage> {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _localities = [];
  bool _loading = true;

  // Variables para drag & drop
  LatLng? _draggingMarkerPos;
  int? _draggingMarkerIndex;

  @override
  void initState() {
    super.initState();
    _fetchLocalities();
  }

  Future<void> _fetchLocalities() async {
    try {
      final data = await LocalityApiService.getAllLocalities();
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

      final typeFromAddress = address['type'] ?? '';
      if (typeFromAddress.contains('village') ||
          typeFromAddress.contains('hamlet') ||
          typeFromAddress.contains('farm')) {
        localityType = 'rural';
      } else {
        localityType = 'urbano';
      }
    } else {
      localityType = 'urbano'; // valor por defecto
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Agregar nueva localidad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                ],
              ),
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    final nowStr = DateTime.now()
                        .toIso8601String()
                        .substring(0, 19)
                        .replaceAll('T', ' ');

                    final doubleLongitude = double.tryParse(longitude);
                    final doubleLatitude = double.tryParse(latitude);

                    if (doubleLongitude == null || doubleLatitude == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coordenadas inválidas')),
                      );
                      return;
                    }

                    final validCountry = country.isEmpty ? 'México' : country;
                    final validMunicipality =
                        municipality.isEmpty ? null : municipality;
                    final validState = state.isEmpty ? null : state;
                    final validStreet = street.isEmpty ? null : street;
                    final validPostalCode =
                        postalCode.isEmpty ? null : postalCode;
                    final validLocalityType =
                        localityType.isEmpty ? 'urbano' : localityType;

                    await LocalityApiService.addLocality({
                      'longitude': doubleLongitude,
                      'latitude': doubleLatitude,
                      'locality': locality,
                      'street': validStreet,
                      'postal_code': validPostalCode,
                      'municipality': validMunicipality,
                      'state': validState,
                      'country': validCountry,
                      'locality_type': validLocalityType,
                      'created_at': nowStr,
                      'updated_at': nowStr,
                    });

                    Navigator.of(context).pop();
                    _fetchLocalities();
                  } catch (e) {
                    print('Error guardando localidad: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error guardando localidad: $e')),
                    );
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
  Future<void> _showEditLocalityDialog(Map<String, dynamic> locality, LatLng newPosition) async {
  final _formKey = GlobalKey<FormState>();

  // Inicializa los valores con los datos actuales y la nueva posición
  String latitude = newPosition.latitude.toString();
  String longitude = newPosition.longitude.toString();
  String localityName = locality['locality'] ?? '';
  String municipality = locality['municipality'] ?? '';
  String street = locality['street'] ?? '';
  String postalCode = locality['postal_code'] ?? '';
  String state = locality['state'] ?? '';
  String country = locality['country'] ?? '';
  String localityType = locality['locality_type'] ?? 'urbano';

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Localidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditableField(
                  label: 'Localidad',
                  initialValue: localityName,
                  validatorMsg: 'La localidad es requerida',
                  onChanged: (v) => localityName = v,
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
                _buildEditableField(
                  label: 'Latitud',
                  initialValue: latitude,
                  validatorMsg: 'Latitud inválida',
                  onChanged: (v) => latitude = v,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                _buildEditableField(
                  label: 'Longitud',
                  initialValue: longitude,
                  validatorMsg: 'Longitud inválida',
                  onChanged: (v) => longitude = v,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final doubleLatitude = double.tryParse(latitude);
                  final doubleLongitude = double.tryParse(longitude);

                  if (doubleLatitude == null || doubleLongitude == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coordenadas inválidas')),
                    );
                    return;
                  }

                  await LocalityApiService.updateLocality(locality['id'], {
                    'latitude': doubleLatitude,
                    'longitude': doubleLongitude,
                    'locality': localityName,
                    'municipality': municipality,
                    'street': street.isEmpty ? null : street,
                    'postal_code': postalCode.isEmpty ? null : postalCode,
                    'state': state.isEmpty ? null : state,
                    'country': country.isEmpty ? 'México' : country,
                    'locality_type': localityType.isEmpty ? 'urbano' : localityType,
                    'updated_at': DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
                  });

                  Navigator.of(context).pop();
                  _fetchLocalities();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Localidad actualizada')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar localidad: $e')),
                  );
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
          currentIndex: -1,
          body: const Center(child: CircularProgressIndicator()), title: '',
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: AppScaffold(
        currentIndex: -1,
        currentDrawerIndex: 5,
        appBarTitle: 'Localidades',
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Material(
                child: const TabBar(
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(icon: Icon(Icons.list), text: 'Lista'),
                    Tab(icon: Icon(Icons.map), text: 'Mapa'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildListView(),
                    _buildMapView(),
                  ],
                ),
              ),
            ],
          ),
        ), title: '',
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
                    content:
                        Text('¿Deseas eliminar la localidad "${loc['locality']}"?'),
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
              await LocalityApiService.deleteLocality(loc['id']);
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final center = _localities.isNotEmpty
        ? LatLng(
            double.tryParse(_localities[0]['latitude'].toString()) ?? 20.967370,
            double.tryParse(_localities[0]['longitude'].toString()) ?? -89.617020,
          )
        : const LatLng(20.967370, -89.617020);

    List<Marker> markers = [];

    for (int i = 0; i < _localities.length; i++) {
      final loc = _localities[i];
      final lat = double.tryParse(loc['latitude'].toString());
      final lng = double.tryParse(loc['longitude'].toString());
      if (lat == null || lng == null) continue;

      // Si estamos arrastrando este marcador, usamos la posición temporal actualizada
      LatLng pos = LatLng(lat, lng);
      if (_draggingMarkerIndex == i && _draggingMarkerPos != null) {
        pos = _draggingMarkerPos!;
      }
      

      markers.add(
        Marker(
          point: pos,
          width: 50,
          height: 50,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _draggingMarkerIndex = i;
                  _draggingMarkerPos = pos;
                });
              },
              onPanUpdate: (details) {
                // Convertir posición del dedo a LatLng usando mapController
                final latlng = _mapController.pointToLatLng(
                  CustomPoint(details.globalPosition.dx, details.globalPosition.dy),
                );
                if (latlng != null) {
                  setState(() {
                    _draggingMarkerPos = latlng;
                  });
                }
              },
onPanEnd: (details) async {
  if (_draggingMarkerIndex != null && _draggingMarkerPos != null) {
    final index = _draggingMarkerIndex!;
    final newPos = _draggingMarkerPos!;
    final locality = _localities[index];

    setState(() {
      _draggingMarkerIndex = null;
      _draggingMarkerPos = null;
    });

    await _showEditLocalityDialog(locality, newPos);
  }
},

              child: Tooltip(
                message: '${loc['locality']}, ${loc['municipality']}',
                child: const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 40,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                ),
              ),
            )
         
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
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
