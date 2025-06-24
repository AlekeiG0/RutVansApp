import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetalleConductorPage extends StatefulWidget {
  final Map<String, String> conductor;

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

  @override
  Widget build(BuildContext context) {
    final conductor = widget.conductor;
    return Scaffold(
      appBar: AppBar(
        title: Text(conductor['nombre'] ?? 'Conductor'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: ClipOval(
                  child: Image.asset(
                    conductor['foto']!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                conductor['nombre']!,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Edad: ${conductor['edad']} años'),
              Text('Experiencia: ${conductor['experiencia']}'),
              Text('Teléfono: ${conductor['telefono']}'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildBtn(Icons.call, 'Llamar', () => _llamar(conductor['telefono']!)),
                  _buildBtn(FontAwesomeIcons.whatsapp, 'WhatsApp', () => _whatsapp(conductor['telefono']!)),
                  _buildBtn(Icons.email, 'Correo', _correo),
                  _buildBtn(Icons.sms, 'SMS', () => _sms(conductor['telefono']!)),
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