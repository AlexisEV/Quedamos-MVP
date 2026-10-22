import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/perfil/data/perfil_repository.dart';
import 'features/salidas/data/salidas_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  final cliente = SupabaseService.cliente;
  runApp(
    QuedamosApp(
      authRepository: AuthRepository(cliente),
      perfilRepository: PerfilRepository(cliente),
      salidasRepository: SalidasRepository(cliente),
    ),
  );
}
