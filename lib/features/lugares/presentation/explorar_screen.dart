import 'package:flutter/material.dart';

import '../../../core/widgets/estado_vacio.dart';

// pestana explorar; catalogo de lugares pendiente de la semana 2
class ExplorarScreen extends StatelessWidget {
  const ExplorarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: const EstadoVacio(
        icono: Icons.explore_outlined,
        titulo: 'Explorar lugares',
        mensaje: 'Sección en construcción.',
      ),
    );
  }
}
