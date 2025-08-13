import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // IMPORTANTE: añade image_picker en pubspec.yaml
import '../../services/coordinator_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/camera.dart';
import '../../services/site_service.dart'; // Asegúrate de tener este servicio
class CoordinatorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> coordinator;

  const CoordinatorDetailsPage({Key? key, required this.coordinator}) : super(key: key);

  @override
  State<CoordinatorDetailsPage> createState() => _CoordinatorDetailsPageState();
}

class _CoordinatorDetailsPageState extends State<CoordinatorDetailsPage> {
  final CoordinatorService _service = CoordinatorService();

  // Paleta corporativa
  final Color primaryColor = const Color(0xFF0A3D62); // Azul oscuro elegante
  final Color secondaryColor = const Color(0xFF3C6382); // Azul grisáceo
  final Color accentColor = const Color(0xFF78E08F); // Verde suave
  final Color dangerColor = const Color(0xFFeb2f06); // Rojo para alertas

  File? _imageFile; // Imagen seleccionada localmente
  final ImagePicker _picker = ImagePicker();

  // Construye la imagen del coordinador
  Widget _buildImage(String? url) {
    if (_imageFile != null) {
      return ClipOval(
        child: Image.file(
          _imageFile!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
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
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
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
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
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
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 130, color: Color(0xFF8D8D8D)),
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Seleccionar imagen de galería o cámara
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
    // Abre tu cámara personalizada y espera la ruta de la imagen recortada
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
  // Si es null (cancelar), no hace nada
}

Future<void> _showForm() async {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController(text: widget.coordinator['user']?['name'] ?? '');
  final emailController = TextEditingController(text: widget.coordinator['user']?['email'] ?? '');
  final phoneController = TextEditingController(text: widget.coordinator['user']?['phone_number'] ?? '');
  final employeeCodeController = TextEditingController(text: widget.coordinator['employee_code'] ?? '');
  final newPasswordController = TextEditingController();

  // Variables para sitios
  List<Map<String, dynamic>> sites = [];
  bool loadingSites = true;
  int? selectedSiteId = widget.coordinator['site_id'];

  // Cargar sitios antes de mostrar el diálogo
  try {
    sites = List<Map<String, dynamic>>.from(await SiteService.getSites());
  } catch (e) {
    // Maneja error si quieres (por ejemplo mostrar mensaje)
  }
  loadingSites = false;

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) {
        Widget _buildCustomTextField(TextEditingController controller, String label,
            {TextInputType inputType = TextInputType.text, bool obscureText = false}) {
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
              obscureText: obscureText,
            ),
          );
        }

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Editar Coordinador',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
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
                        : _buildImage(widget.coordinator['photo_url']),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Toca la imagen para cambiar la foto',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildCustomTextField(nameController, 'Nombre'),
                  _buildCustomTextField(emailController, 'Email', inputType: TextInputType.emailAddress),
                  _buildCustomTextField(phoneController, 'Teléfono', inputType: TextInputType.phone),
                  _buildCustomTextField(employeeCodeController, 'Código empleado'),
                  const SizedBox(height: 10),

                  // Aquí va el dropdown para elegir el sitio
                  loadingSites
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: CircularProgressIndicator(),
                        )
                      : DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: 'Seleccionar Sitio',
                            labelStyle: TextStyle(color: secondaryColor),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                          ),
                          items: sites
                              .map(
                                (site) => DropdownMenuItem<int>(
                                  value: site['id'],
                                  child: Text(site['name']),
                                ),
                              )
                              .toList(),
                          value: selectedSiteId,
                          onChanged: (val) => setDialogState(() {
                            selectedSiteId = val;
                          }),
                          validator: (val) => val == null ? 'Requerido' : null,
                        ),
                  const SizedBox(height: 20),

                  // Solo nueva contraseña (opcional)
                  TextFormField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      labelStyle: TextStyle(color: secondaryColor),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: secondaryColor)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
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

                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final phoneNumber = phoneController.text.trim();
                final employeeCode = employeeCodeController.text.trim();
                final siteId = selectedSiteId;
                final newPassword = newPasswordController.text.trim();

                try {
                  await _service.updateCoordinator(
                    widget.coordinator['id'],
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber,
                    employeeCode: employeeCode,
                    siteId: siteId,
                    photo: _imageFile,
                    newPassword: newPassword.isNotEmpty ? newPassword : null,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Coordinador actualizado'),
                      backgroundColor: accentColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  setState(() {
                    final user = widget.coordinator['user'];
                    user['name'] = name;
                    user['email'] = email;
                    user['phone_number'] = phoneNumber;
                    widget.coordinator['employee_code'] = employeeCode;
                    widget.coordinator['site_id'] = siteId;
                    if (_imageFile == null) {
                      // Mantener URL original si no se cambió la foto
                    } else {
                      widget.coordinator['photo_url'] = null; // refresca después si quieres
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

  Future<void> _deleteCoordinator() async {
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
          '¿Eliminar este coordinador? Esta acción no se puede deshacer.',
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
        await _service.deleteCoordinator(widget.coordinator['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Coordinador eliminado'),
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
  final coord = widget.coordinator;
  final user = coord['user'] ?? {};
  final site = coord['site'] ?? {};

  return AppScaffold(
    appBarTitle: 'Detalle',
    currentIndex: -1,
    currentDrawerIndex: 3,
    body: Container(
      color: Colors.white, // fondo blanco puro
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen con borde blanco y sombra ligera
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
                child: _buildImage(coord['photo_url']),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              user['name'] ?? 'Nombre no disponible',
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
      color: Colors.grey.shade400, // color del contorno
      width: 1.5,                  // grosor del contorno
    ),
  ),
  margin: const EdgeInsets.symmetric(vertical: 15),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
    child: Column(
      children: [
        _buildInfoRow(Icons.email, 'Email', user['email']),
        Divider(color: Colors.grey.shade300, thickness: 1, height: 20),
        _buildInfoRow(Icons.phone, 'Teléfono', user['phone_number']),
        Divider(color: Colors.grey.shade300, thickness: 1, height: 20),
        _buildInfoRow(Icons.badge, 'Código empleado', coord['employee_code']),
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
    // Botón Editar solo icono
    ElevatedButton(
      onPressed: _showForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32), // verde oscuro profesional
        padding: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        shadowColor: Colors.greenAccent.shade700,
      ),
      child: const Icon(Icons.edit, size: 24, color: Colors.white),
    ),

    const SizedBox(width: 20),

    // Botón Eliminar solo icono
    OutlinedButton(
      onPressed: _deleteCoordinator,
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
