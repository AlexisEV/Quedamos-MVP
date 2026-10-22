import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

// pestana mis salidas; lista de planes pendiente de la tarea de crear plan
class MisSalidasScreen extends StatelessWidget {
  const MisSalidasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis salidas')),
      body: const EstadoVacio(
        icono: Icons.groups_outlined,
        titulo: 'Mis salidas',
        mensaje: 'Sección en construcción.',
      ),
    );
  }
}
