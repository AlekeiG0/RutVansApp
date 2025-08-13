import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RutVans',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _movedIn = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _movedIn = true;
      });
    });

    _checkTokenAndValidate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

Future<bool> _validateTokenWithAPI(String token) async {
  try {
    final response = await http.get(
      Uri.parse('https://rutvans.com/api/validate-token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('[API] Status code: ${response.statusCode}');
    print('[API] Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['valid'] == true;
    }
    return false;
  } catch (e) {
    print('[API] Error al validar token: $e');
    return false;
  }
}


  Future<void> _checkTokenAndValidate() async {
    await Future.delayed(const Duration(seconds: 5));

    // Verificar conexión a internet
    var connectivityResult = await Connectivity().checkConnectivity();
    bool hasConnection = connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi;

    if (!hasConnection) {
      if (!mounted) return;

      final Color dialogColor = Colors.deepOrange;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dialogColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 50, color: Colors.white),
                  const SizedBox(height: 15),
                  const Text(
                    'Sin conexión',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No se detectó conexión a Internet.\n\nPor favor, verifica tu red e intenta nuevamente.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: dialogColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'Reintentar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (mounted) {
        _checkTokenAndValidate();
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(title: 'RutVans'),
          ),
        );
      }
      return;
    }

    // Validar token con la API
    final isValidToken = await _validateTokenWithAPI(token);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isValidToken ? const HomePage() : const LoginPage(title: 'RutVans'),
        ),
      );
    }

    // Si el token no es válido, lo eliminamos
    if (!isValidToken) {
      await prefs.remove('token');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // Fondo negro para contraste
        Container(color: Colors.black),

        // Mitad izquierda animada desde fuera hasta la mitad izquierda exacta
        AnimatedAlign(
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          alignment: _movedIn ? const Alignment(-1, 0) : const Alignment(-2, 0),
          child: Container(
            width: screenWidth / 2,
            height: double.infinity,
            color: const Color(0xFFFF6000), // gris oscuro
          ),
        ),

        // Mitad derecha animada desde fuera hasta la mitad derecha exacta
        AnimatedAlign(
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          alignment: _movedIn ? const Alignment(1, 0) : const Alignment(2, 0),
          child: Container(
            width: screenWidth / 2,
            height: double.infinity,
            color: const Color(0xFF454545), // naranja
          ),
        ),

        // Logo y loader centrados con animación
        Center(
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}