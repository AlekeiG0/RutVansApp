import 'dart:io';                       // ← para File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ← image_picker
import '../widgets/App_Scaffold.dart'; // ← tu widget AppScaffold
class HorariosPage extends StatefulWidget {
  const HorariosPage({super.key});

  @override
  State<HorariosPage> createState() => _AsignarHorariosPageState();
}

class _AsignarHorariosPageState extends State<HorariosPage> {
  /// Conductores iniciales con fotos de assets
  final List<Map<String, String>> conductores = [
    {'nombre': 'Juan Pérez', 'foto': 'images/conductor1.jpg'},
    {'nombre': 'Laura Torres', 'foto': 'images/conductor2.jpg'},
    {'nombre': 'Carlos Ruiz', 'foto': 'images/conductor3.jpg'},
  ];

  /// Horarios por conductor
  Map<String, List<Map<String, String>>> horariosPorConductor = {
    "Juan Pérez": [
      {"horario": "Lunes 8 AM – 4 PM", "origen": "Terminal Norte", "destino": "Terminal Sur"},
    ],
    "Laura Torres": [
      {"horario": "Martes 9 AM – 5 PM", "origen": "Terminal Centro", "destino": "Terminal Este"},
    ],
    "Carlos Ruiz": [
      {"horario": "Miércoles 7 AM – 3 PM", "origen": "Terminal Sur", "destino": "Terminal Norte"},
    ],
  };

  /* ────────  AGREGAR CONDUCTOR (con selección de imagen) ──────── */

  void _mostrarFormularioAgregarConductor(BuildContext ctx) {
    final nombreCtrl = TextEditingController();
    File? imagenLocal;

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => imagenLocal = File(picked.path));
      }
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Agregar Conductor",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text("Seleccionar imagen"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await _pickImage();
                      setModalState(() {});          // refresca la miniatura
                    },
                  ),
                  if (imagenLocal != null) ...[
                    const SizedBox(height: 12),
                    ClipOval(
                      child: Image.file(imagenLocal!, width: 90, height: 90, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final nombre = nombreCtrl.text.trim();
                      if (nombre.isEmpty || imagenLocal == null) return;
                      setState(() {
                        conductores.add({'nombre': nombre, 'foto': imagenLocal!.path});
                        horariosPorConductor[nombre] = [];
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ────────  CRUD DE HORARIOS  (sin cambios significativos) ──────── */

  void _mostrarAgregarHorario(BuildContext ctx, String nombre) {
    final horaCtrl = TextEditingController();
    final origenCtrl = TextEditingController();
    final destinoCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Agregar Horario",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: horaCtrl,    decoration: const InputDecoration(labelText: "Horario")),
              TextField(controller: origenCtrl,  decoration: const InputDecoration(labelText: "Origen")),
              TextField(controller: destinoCtrl, decoration: const InputDecoration(labelText: "Destino")),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Guardar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (horaCtrl.text.isEmpty) return;
                  setState(() {
                    horariosPorConductor.putIfAbsent(nombre, () => []);
                    horariosPorConductor[nombre]!.add({
                      "horario": horaCtrl.text,
                      "origen": origenCtrl.text,
                      "destino": destinoCtrl.text,
                    });
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarEditarHorario(BuildContext ctx, String nombre, int idx) {
    final data = horariosPorConductor[nombre]![idx];
    final horaCtrl = TextEditingController(text: data["horario"]);
    final origenCtrl = TextEditingController(text: data["origen"]);
    final destinoCtrl = TextEditingController(text: data["destino"]);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Editar Horario",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: horaCtrl,    decoration: const InputDecoration(labelText: "Horario")),
              TextField(controller: origenCtrl,  decoration: const InputDecoration(labelText: "Origen")),
              TextField(controller: destinoCtrl, decoration: const InputDecoration(labelText: "Destino")),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Actualizar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    horariosPorConductor[nombre]![idx] = {
                      "horario": horaCtrl.text,
                      "origen": origenCtrl.text,
                      "destino": destinoCtrl.text,
                    };
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDetalleHorarios(BuildContext ctx, String nombre) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final lista = horariosPorConductor[nombre] ?? [];
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Horarios de $nombre',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              for (int i = 0; i < lista.length; i++)
                ListTile(
                  title: Text(lista[i]["horario"] ?? ''),
                  subtitle: Text('Origen: ${lista[i]["origen"]}  |  Destino: ${lista[i]["destino"]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepOrange),
                        onPressed: () => _mostrarEditarHorario(ctx, nombre, i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => lista.removeAt(i));
                          Navigator.pop(ctx);
                          _mostrarDetalleHorarios(ctx, nombre); // refrescar
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Agregar Horario"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarAgregarHorario(ctx, nombre);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /* ────────  UI PRINCIPAL ──────── */

@override
Widget build(BuildContext context) {
  return AppScaffold(
    currentIndex: 0,         // Ajusta al índice correcto del bottom nav si aplica
    currentDrawerIndex: 8,   // Ajusta al índice correcto del drawer
    body: Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        itemCount: conductores.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) {
          final data = conductores[i];
          final foto = data['foto']!;
          final isLocal = foto.startsWith('/');     // ruta local de image_picker
          final widgetImg = isLocal
              ? Image.file(File(foto), fit: BoxFit.cover)
              : Image.asset(foto, fit: BoxFit.cover);

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: ClipOval(child: SizedBox(width: 80, height: 80, child: widgetImg)),
                  ),
                  const SizedBox(height: 10),
                  Text(data['nombre']!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: const Text("Ver Horarios"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _mostrarDetalleHorarios(context, data['nombre']!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),

    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.orange,
      child: const Icon(Icons.person_add),
      onPressed: () => _mostrarFormularioAgregarConductor(context),
    ),
  );
}

}
