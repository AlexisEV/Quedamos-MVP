import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

// pestana avisos; historial de notificaciones pendiente de la semana 3
class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: const EstadoVacio(
        icono: Icons.notifications_outlined,
        titulo: 'Avisos',
        mensaje: 'Sección en construcción.',
      ),
    );
  }
}
