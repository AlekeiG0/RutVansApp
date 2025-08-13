import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import '../config/api_config.dart';

class LoginPage extends StatefulWidget {
  final String title;
  const LoginPage({super.key, required this.title});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> showStyledDialog(
    BuildContext context,
    String title,
    String message, {
    Color color = Colors.orange,
    IconData icon = Icons.info_outline,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 50, color: Colors.white),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Cerrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: screenHeight * 0.55,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8E00),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 90),
                Image.asset('assets/images/logo.png', height: 170),
                const SizedBox(height: 10),
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
                const SizedBox(height: 1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.email),
                          SizedBox(width: 8),
                          Text("Correo"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu correo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.lock),
                          SizedBox(width: 8),
                          Text("Contraseña"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            print('Intentando iniciar sesión con email: $email');

                            if (email.isEmpty || password.isEmpty) {
                              print('Campos incompletos');
                              await showStyledDialog(
                                context,
                                'Campos incompletos',
                                'Por favor, completa todos los campos para continuar.',
                                color: Colors.orange,
                                icon: Icons.warning_amber_rounded,
                              );
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              final response = await http.post(
                                Uri.parse('${ApiConfig.baseUrl}/api/login_admin'),
                                headers: {
                                  'Accept': 'application/json',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'email': email,
                                  'password': password,
                                }),
                              );

                              print('Respuesta recibida con status code: ${response.statusCode}');
                              print('Cuerpo de la respuesta: ${response.body}');

                              if (response.statusCode == 200) {
                                final data = json.decode(response.body);
                                final token = data['token'];
                                final user = data['user'];

                                print('Token recibido: $token');
                                print('Usuario recibido: $user');

                                List<dynamic> roles = user['roles'] ?? [];
                                bool isAdmin = roles.any((role) => role['name'] == 'admin');

                                print('Roles del usuario: $roles');
                                print('¿Es admin?: $isAdmin');

                                if (!isAdmin) {
                                  setState(() => _isLoading = false);
                                  await showStyledDialog(
                                    context,
                                    'Acceso denegado',
                                    'No tienes permiso para acceder a esta aplicación.',
                                    color: Colors.red,
                                    icon: Icons.block_rounded,
                                  );
                                  return;
                                }

                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                await prefs.setString('token', token);
                                await prefs.setString('nombre_usuario', user['name'] ?? '');
                                await prefs.setString('email_usuario', user['email'] ?? '');
                                await prefs.setString('foto_usuario', user['profile_photo_url'] ?? '');
                                await prefs.setString('password_usuario', user['password'] ?? '');
                                await prefs.setString('direccion_usuario', user['address'] ?? '');
                                await prefs.setString('telefono_usuario', user['phone_number'] ?? '');
                                await prefs.setString('foto_path_usuario', user['profile_photo_path'] ?? '');
                                await prefs.setString('creado_usuario', user['created_at'] ?? '');
                                await prefs.setString('actualizado_usuario', user['updated_at'] ?? '');
                                final company = user['companies'][0]; // primera y única compañía

await prefs.setInt('company_id', company['id']);
await prefs.setString('company_name', company['name']);
await prefs.setString('company_role', company['role']);
await prefs.setString('company_status', company['status']);
                                
  // Guardar compañías en SharedPreferences como JSON string


                                setState(() => _isLoading = false);

                                print('Inicio de sesión exitoso, navegando a HomePage');
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const HomePage()),
                                );
                              } else {
                                final error = json.decode(response.body)['message'] ?? 'Error al iniciar sesión';
                                print('Error en el login: $error');
                                setState(() => _isLoading = false);
                                await showStyledDialog(
                                  context,
                                  'Error de inicio',
                                  error,
                                  color: Colors.redAccent,
                                  icon: Icons.error_outline,
                                );
                              }
                            } catch (e) {
                              print('Excepción en el login: $e');
                              setState(() => _isLoading = false);
                              await showStyledDialog(
                                context,
                                'Error de conexión',
                                'No se pudo conectar al servidor: $e',
                                color: Colors.deepOrange,
                                icon: Icons.warning_amber,
                              );
                            }
                          },
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: GestureDetector(
                          onTap: () {},
                          child: const Text(
                            '¿Olvidaste la contraseña?',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
