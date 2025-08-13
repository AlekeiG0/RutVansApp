import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cashier_service.dart';
import '../../services/site_service.dart'; // Importa el servicio de sitios
import 'cashier_details_page.dart'; // Página de detalles del cajero
import '../../widgets/app_scaffold.dart';
import '../../widgets/camera.dart';

class CashiersPage extends StatefulWidget {
  const CashiersPage({Key? key}) : super(key: key);

  @override
  State<CashiersPage> createState() => _CashiersPageState();
}

class _CashiersPageState extends State<CashiersPage> {
  final CashierService _service = CashierService();

  List<dynamic> _cashiers = [];
  bool _loading = true;

  File? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  Future<void> _loadCashiers() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getCashiers();
      setState(() {
        _cashiers = data;
      });
    } catch (e) {
      _showMessage('Error cargando cajeros');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showCashierDetails(int id) async {
    try {
      final cashier = await _service.getCashier(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CashierDetailsPage(cashier: cashier),
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

    int? selectedSiteId; // Para guardar la selección del sitio
    List<dynamic> sites = [];
    bool loadingSites = true;

    _selectedPhoto = null;

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
          // Carga sitios solo la primera vez que se construye el dialog
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
              'Nuevo Cajero',
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

                    // Dropdown para seleccionar sitio
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

                  try {
                    print('Intentando crear cajero...');
                    await _service.createCashier(
                      nombre: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                      telefono: phoneController.text.trim(),
                      employeeCode: employeeCodeController.text.trim(),
                      siteId: selectedSiteId ?? 0,
                      fotoCajero: _selectedPhoto,
                    );
                    print('Cajero creado exitosamente.');
                    if (!mounted) return;
                    Navigator.pop(context);
                    _showMessage('Cajero creado');
                    await _loadCashiers();
                  } catch (e, stackTrace) {
                    print('Error creando cajero: $e');
                    print('Stack trace: $stackTrace');
                    if (!mounted) return;
                    _showMessage('Error creando cajero');
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
      appBarTitle: 'Cajeros',
      currentIndex: -1, // Ajusta índices si es necesario para el drawer o bottom nav
      currentDrawerIndex: 4,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCashiers,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _cashiers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final c = _cashiers[i];
                  print('Cajero índice $i: $c');

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _showCashierDetails(c['cashier_id']),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: c['foto'] != null && c['foto'].toString().isNotEmpty
                                  ? NetworkImage(c['foto'])
                                  : null,
                              child: (c['foto'] == null || c['foto'].toString().isEmpty)
                                  ? const Icon(Icons.person, size: 32, color: Colors.blueAccent)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['nombre'] ?? 'Nombre no disponible',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Código empleado: ${c['employee_code'] != null && c['employee_code']!.isNotEmpty ? c['employee_code'] : 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${c['email_usuario'] ?? 'Email no disponible'}',
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
        tooltip: 'Crear Cajero',
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}
