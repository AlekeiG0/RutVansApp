import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetalleConductorPage extends StatefulWidget {
  final Map<String, dynamic> conductor; // dinámico para poder manejar num, null, etc

  const DetalleConductorPage({super.key, required this.conductor});

  @override
  State<DetalleConductorPage> createState() => _DetalleConductorPageState();
}

class _DetalleConductorPageState extends State<DetalleConductorPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imagen;

  void _llamar(String tel) async {
    final Uri url = Uri(scheme: 'tel', path: tel);
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _whatsapp(String tel) async {
    final Uri url = Uri.parse("https://wa.me/$tel");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _correo() async {
    final Uri email = Uri(
      scheme: 'mailto',
      path: 'conductor@correo.com',
      query: 'subject=Ruta&body=Hola, me interesa tu ruta.',
    );
    if (await canLaunchUrl(email)) await launchUrl(email);
  }

  void _sms(String tel) async {
    final Uri sms = Uri(scheme: 'sms', path: tel);
    if (await canLaunchUrl(sms)) await launchUrl(sms);
  }

  void _maps() async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=Halacho,Yucatán");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _web() async {
    final Uri url = Uri.parse("https://flutter.dev");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _abrirCamara() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _imagen = File(image.path));
    }
  }

  Future<void> _abrirGaleria() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imagen = File(image.path));
    }
  }

  Widget _buildBtn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Ink(
          decoration: const ShapeDecoration(
            color: Colors.orange,
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onTap,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildImage(String? ruta) {
    if (ruta == null || ruta.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, size: 50, color: Colors.white),
      );
    }

    if (kIsWeb) {
      if (ruta.startsWith('http') || ruta.startsWith('blob:')) {
        return ClipOval(
          child: Image.network(
            ruta,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 100),
          ),
        );
      } else {
        return ClipOval(
          child: Image.asset(
            ruta,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 100),
          ),
        );
      }
    } else {
      if (ruta.startsWith('/') || ruta.contains('\\')) {
        return ClipOval(
          child: Image.file(
            File(ruta),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 100),
          ),
        );
      } else {
        return ClipOval(
          child: Image.asset(
            ruta,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported, size: 100),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conductor = widget.conductor;
    final nombre = conductor['nombre']?.toString() ?? 'Conductor';
    final edad = conductor['edad']?.toString() ?? 'N/A';
    final experiencia = conductor['experiencia']?.toString() ?? 'N/A';
    final telefono = conductor['telefono']?.toString() ?? '';
    final foto = conductor['foto']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(nombre),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(child: _buildImage(foto)),
              const SizedBox(height: 16),
              Text(
                nombre,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Edad: $edad años'),
              Text('Experiencia: $experiencia'),
              Text('Teléfono: $telefono'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (telefono.isNotEmpty) ...[
                    _buildBtn(Icons.call, 'Llamar', () => _llamar(telefono)),
                    _buildBtn(FontAwesomeIcons.whatsapp, 'WhatsApp', () => _whatsapp(telefono)),
                    _buildBtn(Icons.sms, 'SMS', () => _sms(telefono)),
                  ],
                  _buildBtn(Icons.email, 'Correo', _correo),
                  _buildBtn(Icons.camera_alt, 'Cámara', _abrirCamara),
                  _buildBtn(Icons.photo, 'Galería', _abrirGaleria),
                  _buildBtn(Icons.map, 'Maps', _maps),
                  _buildBtn(Icons.web, 'Web', _web),
                ],
              ),
              if (_imagen != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.file(_imagen!, height: 100),
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text('Calificación del Conductor:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return const Icon(Icons.star, color: Colors.amber);
                }),
              ),
              const SizedBox(height: 20),
              const Text(
                'Comentarios:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Excelente conductor, muy puntual y amable.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}