import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/driver_services.dart';  // Servicio de conductores
import '../../widgets/app_scaffold.dart';
import '../../widgets/camera.dart';
import '../../services/site_service.dart';  // Servicio de sitios

class DriverDetailsPage extends StatefulWidget {
  final Map<String, dynamic> driver;

  const DriverDetailsPage({Key? key, required this.driver}) : super(key: key);

  @override
  State<DriverDetailsPage> createState() => _DriverDetailsPageState();
  
}

class _DriverDetailsPageState extends State<DriverDetailsPage> {
  final DriverService _service = DriverService();

  // Paleta corporativa
  final Color primaryColor = const Color(0xFF0A3D62);
  final Color secondaryColor = const Color(0xFF3C6382);
  final Color accentColor = const Color(0xFF78E08F);
  final Color dangerColor = const Color(0xFFeb2f06);

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Widget _buildImage(String? url) {
    if (_imageFile != null) {
      return ClipOval(
        child: Image.file(
          _imageFile!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
        ),
      );
    }
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        radius: 65,
        backgroundColor: Color(0xFFECECEC),
        child: Icon(Icons.person_outline, size: 65, color: Color(0xFF8D8D8D)),
      );
    }
    if (kIsWeb) {
      return ClipOval(
        child: Image.network(
          url,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
        ),
      );
    } else {
      try {
        if (url.startsWith('http') || url.startsWith('https')) {
          return ClipOval(
            child: Image.network(
              url,
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
            ),
          );
        } else {
          final file = File(url);
          if (file.existsSync()) {
            return ClipOval(
              child: Image.file(
                file,
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
              ),
            );
          } else {
            return const CircleAvatar(
              radius: 65,
              backgroundColor: Color(0xFFECECEC),
              child: Icon(Icons.person_outline, size: 65, color: Color(0xFF8D8D8D)),
            );
          }
        }
      } catch (_) {
        return const CircleAvatar(
          radius: 65,
          backgroundColor: Color(0xFFECECEC),
          child: Icon(Icons.person_outline, size: 65, color: Color(0xFF8D8D8D)),
        );
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 28),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: const Text('Elige la fuente de la imagen'),
        actions: [
          TextButton(
            child: const Text('Cámara'),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: const Text('Galería'),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, null),
          ),
        ],
      ),
    );

    if (source == ImageSource.camera) {
      final croppedImagePath = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (_) => const CameraPage()),
      );
      if (croppedImagePath != null) {
        setState(() {
          _imageFile = File(croppedImagePath);
        });
      }
    } else if (source == ImageSource.gallery) {
      try {
        final pickedFile = await _picker.pickImage(source: source!, maxWidth: 600);
        if (pickedFile != null) {
          setState(() {
            _imageFile = File(pickedFile.path);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _showForm() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: widget.driver['nombre'] ?? '');
    final emailController = TextEditingController(text: widget.driver['email'] ?? '');
    final phoneController = TextEditingController(text: widget.driver['telefono'] ?? '');
    final licenseController = TextEditingController(text: widget.driver['licencia'] ?? '');
    final newPasswordController = TextEditingController();

    // Variables para manejar sitio seleccionado y lista de sitios
    List<Map<String, dynamic>> sites = [];
    int? selectedSiteId = widget.driver['site_id'] is int
        ? widget.driver['site_id']
        : int.tryParse('${widget.driver['site_id']}');

    bool loadingSites = true;

    // Función para cargar sitios
    Future<void> loadSites() async {
      try {
        final rawSites = await SiteService.getSites();
        sites = rawSites.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        sites = [];
      } finally {
        loadingSites = false;
      }
    }

    await loadSites();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Editar Conductor',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            content: loadingSites
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await _pickImage();
                              setDialogState(() {});
                            },
                            child: _imageFile != null
                                ? ClipOval(
                                    child: Image.file(
                                      _imageFile!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _buildImage(widget.driver['foto_conductor']),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Toca la imagen para cambiar la foto',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          _buildCustomTextField(nameController, 'Nombre', formKey),
                          _buildCustomTextField(emailController, 'Email', formKey,
                              inputType: TextInputType.emailAddress),
                          _buildCustomTextField(phoneController, 'Teléfono', formKey,
                              inputType: TextInputType.phone),
                          _buildCustomTextField(licenseController, 'Licencia', formKey),
                          const SizedBox(height: 10),
                          // Dropdown para seleccionar sitio
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Sitio',
                              labelStyle: TextStyle(color: secondaryColor),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: secondaryColor)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                value: selectedSiteId,
                                hint: const Text('Selecciona un sitio'),
                                items: sites.map((site) {
                                  final id = site['id'] ?? site['site_id'];
                                  final name = site['name'] ?? 'Sin nombre';
                                  return DropdownMenuItem<int>(
                                    value: id is int ? id : int.tryParse('$id'),
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedSiteId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Nueva contraseña',
                              labelStyle: TextStyle(color: secondaryColor),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: secondaryColor)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor)),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar',
                    style: TextStyle(color: dangerColor, fontWeight: FontWeight.w600)),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Selecciona un sitio'),
                        backgroundColor: dangerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }

                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final phoneNumber = phoneController.text.trim();
                  final license = licenseController.text.trim();
                  final newPassword = newPasswordController.text.trim();

                  try {
                    await _service.updateDriver(
                      widget.driver['driver_id'] ?? widget.driver['id'],
                      nombre: name,
                      email: email,
                      telefono: phoneNumber,
                      licencia: license,
                      siteId: selectedSiteId,
                      fotoConductor: _imageFile,
                      newPassword: newPassword.isNotEmpty ? newPassword : null,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Conductor actualizado'),
                        backgroundColor: accentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    setState(() {
                      widget.driver['nombre'] = name;
                      widget.driver['email'] = email;
                      widget.driver['telefono'] = phoneNumber;
                      widget.driver['licencia'] = license;
                      widget.driver['site_id'] = selectedSiteId;
                      if (_imageFile != null) {
                        widget.driver['foto_conductor'] = null;
                      }
                      _imageFile = null;
                    });
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error actualizando: $e'),
                        backgroundColor: dangerColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                child: const Text('Guardar', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomTextField(TextEditingController controller, String label, GlobalKey<FormState> formKey,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: secondaryColor),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
        keyboardType: inputType,
      ),
    );
  }

  Future<void> _deleteDriver() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(
              'Confirmar eliminación',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          '¿Eliminar este conductor? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 5,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteDriver(widget.driver['driver_id'] ?? widget.driver['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conductor eliminado'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error eliminando: $e'),
            backgroundColor: dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final site = driver['site'] ?? {};

   return AppScaffold(
  appBarTitle: 'Detalle Conductor',
  currentIndex: 2, // Cambia si tienes un índice fijo para conductores
  currentDrawerIndex: 2,
  body: Container(
    color: Colors.white,
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (_) {
              // 🔍 Log completo
              print("DEBUG - driver: $driver");
              print("DEBUG - site: $site");

              // 🔍 Log campos específicos
              print("DEBUG - foto_conductor: ${driver['foto_conductor']}");
              print("DEBUG - nombre: ${driver['nombre']}");
              print("DEBUG - email: ${driver['email']}");
              print("DEBUG - telefono: ${driver['telefono']}");
              print("DEBUG - licencia: ${driver['licencia']}");
              print("DEBUG - sitio name: ${site['name']}");
              print("DEBUG - sitio address: ${site['address']}");

              return const SizedBox.shrink(); // No muestra nada visual
            },
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: ClipOval(
              child: _buildImage(driver['foto_conductor']),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            driver['nombre'] ?? 'Nombre no disponible',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          Card(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email, 'Email', driver['email']),
                  Divider(color: Colors.grey.shade300, thickness: 1, height: 20),
                  _buildInfoRow(Icons.phone, 'Teléfono', driver['telefono']),
                  Divider(color: Colors.grey.shade300, thickness: 1, height: 20),
                  _buildInfoRow(Icons.card_membership, 'Licencia', driver['licencia']),
                  Divider(color: Colors.grey.shade300, thickness: 1, height: 20),
                  _buildInfoRow(Icons.location_city, 'Sitio', site['name']),
                  Divider(color: Colors.grey.shade300, thickness: 1, height: 20),
                  _buildInfoRow(Icons.location_on, 'Dirección', site['address']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _showForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  shadowColor: Colors.greenAccent.shade700,
                ),
                child: const Icon(Icons.edit, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 20),
              OutlinedButton(
                onPressed: _deleteDriver,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFB71C1C), width: 2),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ).copyWith(
                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(MaterialState.pressed)) {
                        return const Color(0xFFB71C1C).withOpacity(0.15);
                      }
                      return null;
                    },
                  ),
                ),
                child: const Icon(Icons.delete_outline, size: 24, color: Color(0xFFB71C1C)),
              ),
            ],
          )
        ],
      ),
    ),
  ),
);

  }
}
