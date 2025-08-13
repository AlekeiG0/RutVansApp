import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class PhotoPreviewPage1 extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;

  const PhotoPreviewPage1({Key? key, this.imageFile, this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageFile != null) {
      imageWidget = Image.file(imageFile!, fit: BoxFit.contain);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (kIsWeb || imageUrl!.startsWith('http')) {
        imageWidget = Image.network(imageUrl!, fit: BoxFit.contain);
      } else {
        imageWidget = Image.file(File(imageUrl!), fit: BoxFit.contain);
      }
    } else {
      imageWidget = const Center(child: Text('No hay imagen para mostrar'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Previsualizar foto')),
      body: Center(child: imageWidget),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false), // Cancelar
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // Guardar
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
