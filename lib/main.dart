import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/lugares/data/lugares_repository.dart';
import 'features/lugares/data/propuestas_repository.dart';
import 'features/perfil/data/perfil_repository.dart';
import 'features/salidas/data/salidas_repository.dart';
import 'features/votacion/data/votacion_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  final cliente = SupabaseService.cliente;
  final salidas = SalidasRepository(cliente);
  runApp(
    QuedamosApp(
      authRepository: AuthRepository(cliente),
      perfilRepository: PerfilRepository(cliente),
      salidasRepository: salidas,
      lugaresRepository: LugaresRepository(cliente),
      propuestasRepository: PropuestasRepository(cliente),
      votacionRepository: VotacionRepository(cliente, salidas),
    ),
  );
}
