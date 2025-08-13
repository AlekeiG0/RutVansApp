import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/coordinator_service.dart';
import '../../services/site_service.dart'; // <-- IMPORTANTE: servicio para obtener sitios
import 'coordinator_details_page.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/camera.dart';

class CoordinatorsPage extends StatefulWidget {
  const CoordinatorsPage({Key? key}) : super(key: key);

  @override
  State<CoordinatorsPage> createState() => _CoordinatorsPageState();
}

class _CoordinatorsPageState extends State<CoordinatorsPage> {
  final CoordinatorService _service = CoordinatorService();

  List<dynamic> _coordinators = [];
  bool _loading = true;

  List<Map<String, dynamic>> _sites = [];
  bool _loadingSites = true;
  int? _selectedSiteId;

  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _loadSites();
    _loadCoordinators();
  }

  Future<void> _loadSites() async {
    setState(() => _loadingSites = true);
    try {
      final sitesData = await SiteService.getSites(); // Debes implementar este método en tu SiteService
      setState(() {
        _sites = List<Map<String, dynamic>>.from(sitesData);
      });
    } catch (e) {
      _showMessage('Error cargando sitios');
    } finally {
      setState(() => _loadingSites = false);
    }
  }

  Future<void> _loadCoordinators() async {
    setState(() => _loading = true);
    try {
      final data = await _service.fetchCoordinators();
      setState(() {
        _coordinators = data;
      });
    } catch (e) {
      _showMessage('Error cargando coordinadores');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showCoordinatorDetails(int id) async {
    try {
      final coordinator = await _service.fetchCoordinator(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CoordinatorDetailsPage(coordinator: coordinator),
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
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final employeeCodeController = TextEditingController();

    _selectedPhoto = null;
    _selectedSiteId = null; // Reiniciamos selección de sitio al abrir formulario

    // Colores corporativos
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
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Text(
              'Nuevo Coordinador',
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
                    _buildCustomTextField(emailController, 'Email', inputType: TextInputType.emailAddress),
                    _buildCustomTextField(passwordController, 'Password', obscureText: true),
                    _buildCustomTextField(phoneController, 'Teléfono', inputType: TextInputType.phone),
                    _buildCustomTextField(employeeCodeController, 'Código empleado'),

                    const SizedBox(height: 10),

                    _loadingSites
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: CircularProgressIndicator(),
                          )
                        : DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Seleccionar Sitio',
                              labelStyle: TextStyle(color: secondaryColor),
                              enabledBorder:
                                  UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
                              focusedBorder:
                                  UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                            ),
                            items: _sites.map((site) {
                              return DropdownMenuItem<int>(
                                value: site['id'],
                                child: Text(site['name']),
                              );
                            }).toList(),
                            value: _selectedSiteId,
                            onChanged: (val) => setDialogState(() {
                              _selectedSiteId = val;
                            }),
                            validator: (val) => val == null ? 'Requerido' : null,
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

                  try {
                    print('Intentando crear coordinador...');
                    await _service.createCoordinator(
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      phoneNumber: phoneController.text.trim(),
                      employeeCode: employeeCodeController.text.trim(),
                      siteId: _selectedSiteId,
                      photo: _selectedPhoto,
                    );
                    print('Coordinador creado exitosamente.');
                    if (!mounted) return;
                    Navigator.pop(context);
                    _showMessage('Coordinador creado');
                    await _loadCoordinators();
                  } catch (e, stackTrace) {
                    print('Error creando coordinador: $e');
                    print('Stack trace: $stackTrace');
                    if (!mounted) return;
                    _showMessage('Error creando coordinador');
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
      appBarTitle: 'Coordinadores',
      currentIndex: -1,
      currentDrawerIndex: 3,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCoordinators,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _coordinators.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final c = _coordinators[i];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showCoordinatorDetails(c['id']),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: c['photo_url'] != null && c['photo_url'].isNotEmpty
                                  ? NetworkImage(c['photo_url'])
                                  : null,
                              child: (c['photo_url'] == null || c['photo_url'].isEmpty)
                                  ? const Icon(Icons.person, size: 32, color: Colors.blueAccent)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['user']['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Código empleado: ${c['employee_code']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${c['user']['email']}',
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
        tooltip: 'Crear Coordinador',
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
