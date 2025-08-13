import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  CameraLensDirection _currentDirection = CameraLensDirection.front;

  // Controlador para animación flash al tomar foto
  late AnimationController _flashAnimationController;

  @override
  void initState() {
    super.initState();
    _flashAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initCamera(_currentDirection);
  }

  Future<void> _initCamera(CameraLensDirection direction) async {
    _cameras = await availableCameras();

    final selectedCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == direction,
      orElse: () => _cameras!.first,
    );

    await _controller?.dispose();

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high, // Mejor calidad
      enableAudio: false,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraReady = true;
      _currentDirection = direction;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _flashAnimationController.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    final newDirection = (_currentDirection == CameraLensDirection.back)
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    setState(() {
      _isCameraReady = false;
    });

    await _initCamera(newDirection);
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    // Animación flash
    await _flashAnimationController.forward();
    await _flashAnimationController.reverse();

    final image = await _controller!.takePicture();

    final confirmedPath = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoPreviewPage(imagePath: image.path),
      ),
    );

    if (confirmedPath != null) {
      Navigator.pop(context, confirmedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isCameraReady
            ? Stack(
                children: [
                  CameraPreview(_controller!),

                  // Animación flash blanca superpuesta
                  FadeTransition(
                    opacity: _flashAnimationController,
                    child: Container(color: Colors.white.withOpacity(0.7)),
                  ),

                  // Barra superior con título y botón cerrar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tomar Foto',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Cerrar cámara',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botón para cambiar cámara
                  Positioned(
                    top: 70,
                    right: 20,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black54,
                      onPressed: _switchCamera,
                      child: const Icon(Icons.switch_camera, color: Colors.white),
                      tooltip: 'Cambiar cámara',
                    ),
                  ),

                  // Botón para tomar foto (grande y centrado)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _takePicture,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black87, size: 36),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}

class PhotoPreviewPage extends StatefulWidget {
  final String imagePath;

  const PhotoPreviewPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  _PhotoPreviewPageState createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  final CropController _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Confirmar Foto', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context, null),
          tooltip: 'Volver a cámara',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white70, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Crop(
                  controller: _cropController,
                  image: File(widget.imagePath).readAsBytesSync(),
                  aspectRatio: 1.0,
                  onCropped: (croppedData) async {
                    setState(() {
                      _isCropping = false;
                    });

                    final tempDir = Directory.systemTemp;
                    final file = await File(
                            '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png')
                        .writeAsBytes(croppedData);

                    Navigator.pop(context, file.path);
                  },
                ),
              ),
            ),
          ),
          if (_isCropping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(color: Colors.greenAccent),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Repetir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.pop(context, null),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                    shadowColor: Colors.greenAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCropping = true;
                    });
                    _cropController.crop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
