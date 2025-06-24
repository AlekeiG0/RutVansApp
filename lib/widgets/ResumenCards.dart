import 'package:flutter/material.dart';
// importa tu InfoCard si está separada

class ResumenCards extends StatelessWidget {
  final String rutasActivas;
  final String viajesHoy;
  final String conductores;
  final String ingresosTotales;

  const ResumenCards({
    super.key,
    required this.rutasActivas,
    required this.viajesHoy,
    required this.conductores,
    required this.ingresosTotales,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: InfoCard(
              icon: Icons.directions_bus,
              value: viajesHoy,
              label: 'Viajes de hoy',
              backgroundColor: const Color(0xFFD0F2FF),
              iconColor: const Color(0xFF1E88E5),
              compact: true,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: InfoCard(
              icon: Icons.people,
              value: conductores,
              label: 'Conductores',
              backgroundColor: const Color(0xFFFFF4E5),
              iconColor: const Color(0xFFF57C00),
              compact: true,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: InfoCard(
              icon: Icons.location_on,
              value: rutasActivas,
              label: 'Rutas activas',
              backgroundColor: const Color(0xFFE6F4EA),
              iconColor: const Color(0xFF43A047),
              compact: true,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: InfoCard(
              icon: Icons.attach_money,
              value: ingresosTotales,
              label: 'Ingresos totales',
              backgroundColor: const Color(0xFFFFEBEE),
              iconColor: const Color(0xFFD32F2F),
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool compact;

  const InfoCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.backgroundColor = const Color(0xFFFFE6C7),
    this.iconColor = const Color(0xFFFF6000),
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 36.0;
    final valueFontSize = compact ? 16.0 : 20.0;
    final labelFontSize = compact ? 11.0 : 13.0;
    final verticalPadding = compact ? 12.0 : 20.0;
    final horizontalPadding = compact ? 12.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            SizedBox(height: compact ? 6 : 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: valueFontSize,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: labelFontSize,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}