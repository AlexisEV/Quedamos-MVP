import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

// p11 registro e inicio de sesion; contenido pendiente de la tarea de auth
class AccesoScreen extends StatelessWidget {
  const AccesoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EstadoVacio(
          icono: Icons.lock_outline,
          titulo: 'Quedamos',
          mensaje: 'Registro e inicio de sesión en construcción.',
        ),
      ),
    );
  }
}
