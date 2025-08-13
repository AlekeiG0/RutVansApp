import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/usuario_service.dart';
import '../widgets/app_scaffold.dart';

// IMPORTA AQUÍ TU PÁGINA DE CÁMARA
import '../widgets/camera.dart';  // <- Cambia esto según tu estructura

class UsuarioPerfilPage extends StatefulWidget {
  const UsuarioPerfilPage({super.key});

  @override
  State<UsuarioPerfilPage> createState() => _UsuarioPerfilPageState();
}

class _UsuarioPerfilPageState extends State<UsuarioPerfilPage> {
  String nombre = '';
  String email = '';
  String foto = '';
  String direccion = '';
  String telefono = '';
  String fechaCreacion = '';
  String fechaActualizacion = '';

  File? nuevaFoto;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nombreCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController direccionCtrl;
  late TextEditingController telefonoCtrl;

  final Color primaryColor = const Color(0xFF0A3D62);
  final Color secondaryColor = const Color(0xFF3C6382);
  final Color backgroundColor = const Color(0xFFF4F6F8);
  final Color cardColor = Colors.white;
  final Color iconColor = const Color(0xFF0A3D62);

  @override
  void initState() {
    super.initState();
    cargarPerfilDesdeApi();

    nombreCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    direccionCtrl = TextEditingController();
    telefonoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    emailCtrl.dispose();
    direccionCtrl.dispose();
    telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarPerfilDesdeApi() async {
    try {
      final perfil = await UsuarioService.obtenerPerfil();

      if (perfil != null) {
        setState(() {
          nombre = perfil['name'] ?? '';
          email = perfil['email'] ?? '';
          foto = perfil['profile_photo_url'] ?? '';
          direccion = perfil['address'] ?? '';
          telefono = perfil['phone_number'] ?? '';
          fechaCreacion = formatearFecha(perfil['created_at'] ?? '');
          fechaActualizacion = formatearFecha(perfil['updated_at'] ?? '');

          nombreCtrl.text = nombre;
          emailCtrl.text = email;
          direccionCtrl.text = direccion;
          telefonoCtrl.text = telefono;
        });
      }
    } catch (e) {
      // Manejo sencillo de error, puedes mejorar
    }
  }

  String formatearFecha(String fechaOriginal) {
    try {
      final DateTime fecha = DateTime.parse(fechaOriginal);
      return DateFormat('dd/MM/yyyy – HH:mm').format(fecha);
    } catch (_) {
      return 'Formato no válido';
    }
  }

  Future<void> mostrarFormularioEditar() async {
    nuevaFoto = null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> seleccionarFotoDialog() async {
              final opcion = await showDialog<String>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Seleccionar foto'),
                  children: [
                    SimpleDialogOption(
                      child: const Text('Galería'),
                      onPressed: () => Navigator.pop(context, 'gallery'),
                    ),
                    SimpleDialogOption(
                      child: const Text('Cámara'),
                      onPressed: () => Navigator.pop(context, 'camera'),
                    ),
                    SimpleDialogOption(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context, null),
                    ),
                  ],
                ),
              );

              if (opcion == 'gallery') {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 75,
                );
                if (pickedFile != null) {
                  setDialogState(() {
                    nuevaFoto = File(pickedFile.path);
                  });
                }
              } else if (opcion == 'camera') {
                final rutaFoto = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraPage()),
                );
                if (rutaFoto != null && rutaFoto.isNotEmpty) {
                  setDialogState(() {
                    nuevaFoto = File(rutaFoto);
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Editar Perfil',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: seleccionarFotoDialog,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: secondaryColor.withOpacity(0.1),
                          backgroundImage: nuevaFoto != null
                              ? FileImage(nuevaFoto!)
                              : (foto.isNotEmpty
                                  ? NetworkImage(foto)
                                  : const AssetImage('assets/images/default_conductor.png') as ImageProvider),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              backgroundColor: primaryColor,
                              radius: 14,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(nombreCtrl, 'Nombre', 'Ingrese nombre', false, TextInputType.text),
                      const SizedBox(height: 12),
                      _buildTextField(emailCtrl, 'Email', 'Ingrese correo electrónico', false, TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildTextField(direccionCtrl, 'Dirección', 'Ingrese dirección', true, TextInputType.text),
                      const SizedBox(height: 12),
                      _buildTextField(telefonoCtrl, 'Teléfono', 'Ingrese teléfono', true, TextInputType.phone),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      bool exito = false;
                      try {
                        exito = await UsuarioService.actualizarPerfil(
                          name: nombreCtrl.text,
                          email: emailCtrl.text,
                          address: direccionCtrl.text,
                          phoneNumber: telefonoCtrl.text,
                          profilePhoto: nuevaFoto,
                        );
                      } catch (_) {}

                      if (exito) {
                        Navigator.pop(context);
                        await cargarPerfilDesdeApi();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Perfil actualizado con éxito'),
                            backgroundColor: primaryColor,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Error al actualizar perfil'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String placeholder, bool optional, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: optional
          ? null
          : (value) {
              if (value == null || value.trim().isEmpty) return '$label es requerido';
              if (label == 'Email') {
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                if (!emailRegex.hasMatch(value)) return 'Email inválido';
              }
              return null;
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      appBarTitle: 'Perfil del Usuario',
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Card(
          color: cardColor,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: secondaryColor.withOpacity(0.1),
                  backgroundImage: foto.isNotEmpty
                      ? NetworkImage(foto)
                      : const AssetImage('assets/images/default_conductor.png') as ImageProvider,
                ),
                const SizedBox(height: 20),
                Text(
                  nombre,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 28),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 18),
                infoTile(Icons.home_outlined, 'Dirección', direccion),
                infoTile(Icons.phone_outlined, 'Teléfono', telefono),
                infoTile(Icons.calendar_today_outlined, 'Creado el', fechaCreacion),
                infoTile(Icons.update_outlined, 'Actualizado el', fechaActualizacion),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: mostrarFormularioEditar,
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text('Editar perfil', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget infoTile(IconData icono, String titulo, String valor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Icon(icono, color: iconColor, size: 28),
      title: Text(
        titulo,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.3,
        ),
      ),
      subtitle: Text(
        valor.isNotEmpty ? valor : 'No disponible',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
