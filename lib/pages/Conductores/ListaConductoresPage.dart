import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/driver_services.dart';
import '../../services/site_service.dart';
import 'driver_details_page.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/camera.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({Key? key}) : super(key: key);

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  final DriverService _service = DriverService();

  List<dynamic> _drivers = [];
  bool _loading = true;
  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _loading = true);
    try {
      final data = await DriverService.getDrivers();
      setState(() {
        _drivers = data;
      });
    } catch (e) {
      _showMessage('Error cargando conductores');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDriverDetails(int id) async {
    try {
      // Asumiendo que tienes un método getDriver similar en DriverService
      final driver = await DriverService.getDriver(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDetailsPage(driver: driver),
        ),
      );
    } catch (e) {
      _showMessage('Error al obtener detalles');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showForm() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final licenseController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    int? selectedSiteId;
    List<dynamic> sites = [];
    bool loadingSites = true;

    _selectedPhoto = null;

    final Color primaryColor = const Color(0xFF0A3D62);
    final Color secondaryColor = const Color(0xFF3C6382);
    final Color dangerColor = const Color(0xFFeb2f06);

    Widget _buildCustomTextField(TextEditingController controller, String label,
        {TextInputType inputType = TextInputType.text, bool obscureText = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: inputType,
          validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: secondaryColor),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
          ),
        ),
      );
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingSites) {
            SiteService.getSites().then((data) {
              setDialogState(() {
                sites = data;
                loadingSites = false;
              });
            }).catchError((e) {
              setDialogState(() {
                loadingSites = false;
              });
              _showMessage('Error cargando sitios');
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Text(
              'Nuevo Conductor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Galería'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final picker = ImagePicker();
                                    final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 600,
                                      maxHeight: 600,
                                    );
                                    if (pickedFile != null) {
                                      setDialogState(() {
                                        _selectedPhoto = File(pickedFile.path);
                                      });
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Cámara'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final imagePath = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CameraPage()),
                                    );
                                    if (imagePath != null) {
                                      setDialogState(() {
                                        _selectedPhoto = File(imagePath);
                                      });
                                    }
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.close),
                                  title: const Text('Cancelar'),
                                  onTap: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: _selectedPhoto != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedPhoto!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFECECEC),
                              child: const Icon(Icons.person_outline, size: 60, color: Color(0xFF8D8D8D)),
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toca la imagen para seleccionar foto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    _buildCustomTextField(nameController, 'Nombre'),
                    _buildCustomTextField(licenseController, 'Licencia'),
                    _buildCustomTextField(emailController, 'Email', inputType: TextInputType.emailAddress),
                    _buildCustomTextField(passwordController, 'Password', obscureText: true),
                    _buildCustomTextField(phoneController, 'Teléfono', inputType: TextInputType.phone),

                    const SizedBox(height: 10),

                    loadingSites
                        ? const CircularProgressIndicator()
                        : DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Seleccione un Sitio',
                              labelStyle: TextStyle(color: secondaryColor),
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
                              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                            ),
                            items: sites.map<DropdownMenuItem<int>>((site) {
                              return DropdownMenuItem<int>(
                                value: site['id'],
                                child: Text(site['name'] ?? 'Sin nombre'),
                              );
                            }).toList(),
                            value: selectedSiteId,
                            onChanged: (val) {
                              setDialogState(() {
                                selectedSiteId = val;
                              });
                            },
                            validator: (value) => value == null ? 'Seleccione un sitio' : null,
                          ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar', style: TextStyle(color: dangerColor, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (selectedSiteId == null) {
                    _showMessage('Seleccione un sitio');
                    return;
                  }

                  try {
                    print('Intentando crear conductor...');
                    await DriverService.createDriver(
                      nombre: nameController.text.trim(),
                      licencia: licenseController.text.trim(),
                      telefono: phoneController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      siteId: selectedSiteId!,
                      fotoConductor: _selectedPhoto,
                    );
                    print('Conductor creado exitosamente.');
                    if (!mounted) return;
                    Navigator.pop(context);
                    _showMessage('Conductor creado');
                    await _loadDrivers();
                  } catch (e, stackTrace) {
                    print('Error creando conductor: $e');
                    print('Stack trace: $stackTrace');
                    if (!mounted) return;
                    _showMessage('Error creando conductor');
                  }
                },
                child: const Text('Crear', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Conductores',
      currentIndex: 2,
      currentDrawerIndex: 2,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDrivers,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _drivers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final d = _drivers[i];
                  print('Conductor índice $i: $d');

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showDriverDetails(d['id'] ?? d['driver_id'] ?? 0),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: d['foto_conductor'] != null && d['foto_conductor'].toString().isNotEmpty
                                  ? NetworkImage(d['foto_conductor'])
                                  : null,
                              child: (d['foto_conductor'] == null || d['foto_conductor'].toString().isEmpty)
                                  ? const Icon(Icons.person, size: 32, color: Colors.blueAccent)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['nombre'] ?? 'Nombre no disponible',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Licencia: ${d['licencia'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${d['email'] ?? 'Email no disponible'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        tooltip: 'Crear Conductor',
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
