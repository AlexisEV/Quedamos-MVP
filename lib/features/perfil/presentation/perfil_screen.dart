import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

// pestana perfil; datos de cuenta y cierre de sesion pendientes de la tarea de auth
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const EstadoVacio(
        icono: Icons.account_circle_outlined,
        titulo: 'Perfil',
        mensaje: 'Sección en construcción.',
      ),
    );
  }
}
