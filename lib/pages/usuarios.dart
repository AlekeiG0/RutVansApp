import 'package:flutter/material.dart';
import '../dbHelper/horariost.dart';
import '../widgets/App_Scaffold.dart'; // ← tu widget AppScaffold

class UsuarioPage extends StatefulWidget {
  final String email; // Recibe email para buscar perfil

  const UsuarioPage({super.key, required this.email});

  @override
  State<UsuarioPage> createState() => _UsuarioPageState();
}

class _UsuarioPageState extends State<UsuarioPage> {
  Map<String, dynamic>? usuario;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final userData = await MongoDatabase.getUserByEmail(widget.email);
      if (userData != null) {
        setState(() {
          usuario = userData;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Usuario no encontrado";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Error al cargar datos: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 250, 169, 63), Color.fromARGB(251, 255, 177, 60)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : error != null
                  ? Center(
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Mi Perfil',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Card de perfil
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: const Color(0xFFFF8C42),
                                  backgroundImage: usuario!['photo'] != null
                                      ? NetworkImage(usuario!['photo'])
                                      : null,
                                  child: usuario!['photo'] == null
                                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  usuario!['name'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  usuario!['email'] ?? '',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                Chip(
                                  label: Text(
                                    usuario!['role'] ?? 'Usuario',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.orange.shade700,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Opciones
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _opcion(
                                  icon: Icons.edit,
                                  text: 'Editar Perfil',
                                  onTap: () {
                                    // Aquí función para editar perfil
                                  },
                                ),
                                _opcion(
                                  icon: Icons.lock,
                                  text: 'Cambiar Contraseña',
                                  onTap: () {
                                    // Aquí función para cambiar contraseña
                                  },
                                ),
                                _opcion(
                                  icon: Icons.logout,
                                  text: 'Cerrar Sesión',
                                  color: const Color.fromARGB(255, 255, 108, 82),
                                  onTap: () {
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _opcion({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(fontSize: 16, color: color),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}